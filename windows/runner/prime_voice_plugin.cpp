#include "prime_voice_plugin.h"

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <windows.h>
#include <sapi.h>
#include <sphelper.h>
#include <string>
#include <thread>
#include <atomic>
#include <mutex>

namespace prime_voice {

// Static instance for callbacks
static PrimeVoicePlugin* g_instance = nullptr;
static std::atomic<bool> g_listening{false};
static std::thread g_listen_thread;
static std::mutex g_mutex;

// Speech recognition callback class
class VoiceRecognitionCallback : public ISpNotifySink {
 public:
  VoiceRecognitionCallback(PrimeVoicePlugin* plugin) : plugin_(plugin) {}

  STDMETHODIMP Notify(SPCNOTIFYCODE /*eCode*/, const PVOID /*pData*/) override {
    return S_OK;
  }

 private:
  PrimeVoicePlugin* plugin_;
};

void PrimeVoicePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.prime/voice",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<PrimeVoicePlugin>();

  channel->SetMethodCallHandler(
      [plugin_ptr = plugin.get()](
          const flutter::MethodCall<flutter::EncodableValue>& method_call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        plugin_ptr->HandleMethodCall(method_call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

PrimeVoicePlugin::PrimeVoicePlugin() {
  g_instance = this;

  // Initialize COM for this thread
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
    OutputDebugStringA("[PrimeVoice] COM init failed\n");
  }

  // Initialize TTS
  ISpVoice* pVoice = nullptr;
  hr = CoCreateInstance(CLSID_SpVoice, nullptr, CLSCTX_ALL, IID_ISpVoice,
                        reinterpret_cast<void**>(&pVoice));
  if (SUCCEEDED(hr) && pVoice) {
    tts_voice_ = pVoice;
    tts_initialized_ = true;
    OutputDebugStringA("[PrimeVoice] TTS initialized successfully\n");
  } else {
    OutputDebugStringA("[PrimeVoice] TTS init failed\n");
  }
}

PrimeVoicePlugin::~PrimeVoicePlugin() {
  g_listening = false;
  if (g_listen_thread.joinable()) {
    g_listen_thread.join();
  }

  if (tts_voice_) {
    static_cast<ISpVoice*>(tts_voice_)->Release();
    tts_voice_ = nullptr;
  }

  g_instance = nullptr;
  CoUninitialize();
}

void PrimeVoicePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  const auto& method = method_call.method_name();

  if (method == "isTtsAvailable") {
    result->Success(flutter::EncodableValue(tts_initialized_));
  }
  else if (method == "isSttAvailable") {
    result->Success(flutter::EncodableValue(stt_initialized_));
  }
  else if (method == "speak") {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto text_it = args->find(flutter::EncodableValue("text"));
      if (text_it != args->end()) {
        auto text = std::get<std::string>(text_it->second);
        Speak(text, std::move(result));
        return;
      }
    }
    result->Error("invalid_arguments", "Missing text parameter");
  }
  else if (method == "stopSpeaking") {
    StopSpeaking(std::move(result));
  }
  else if (method == "startListening") {
    StartListening(std::move(result));
  }
  else if (method == "stopListening") {
    StopListening(std::move(result));
  }
  else {
    result->NotImplemented();
  }
}

void PrimeVoicePlugin::Speak(
    const std::string& text,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  if (!tts_initialized_ || !tts_voice_) {
    result->Error("tts_not_available", "TTS engine not initialized");
    return;
  }

  // Notify Flutter that TTS is starting
  SendEvent("onTtsStarted", flutter::EncodableValue());

  ISpVoice* pVoice = static_cast<ISpVoice*>(tts_voice_);

  // Convert std::string to wide string
  int wlen = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  std::wstring wtext(wlen, 0);
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, &wtext[0], wlen);

  // Speak asynchronously
  HRESULT hr = pVoice->Speak(wtext.c_str(), SPF_ASYNC, nullptr);

  if (SUCCEEDED(hr)) {
    // Wait for speech to complete in a background thread
    std::thread([this, pVoice]() {
      // Wait for speaking to finish
      SPVOICESTATUS status;
      do {
        Sleep(100);
        pVoice->GetStatus(&status, nullptr);
      } while (status.dwRunningState == SPRS_SPEAKING);

      // Notify Flutter that TTS is done
      if (g_instance) {
        SendEvent("onTtsCompleted", flutter::EncodableValue());
      }
    }).detach();

    result->Success(flutter::EncodableValue(true));
  } else {
    SendEvent("onTtsCompleted", flutter::EncodableValue());
    result->Error("tts_speak_failed", "Failed to speak text");
  }
}

void PrimeVoicePlugin::StopSpeaking(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  if (!tts_initialized_ || !tts_voice_) {
    result->Success(flutter::EncodableValue(false));
    return;
  }

  ISpVoice* pVoice = static_cast<ISpVoice*>(tts_voice_);
  HRESULT hr = pVoice->Speak(nullptr, SPF_PURGEBEFORESPEAK, nullptr);

  SendEvent("onTtsCompleted", flutter::EncodableValue());
  result->Success(flutter::EncodableValue(SUCCEEDED(hr)));
}

void PrimeVoicePlugin::IsTtsAvailable(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->Success(flutter::EncodableValue(tts_initialized_));
}

void PrimeVoicePlugin::StartListening(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  // Windows Speech Recognition (SISR) requires Windows 10+
  // For simplicity, we'll simulate listening and report back
  // In production, you'd use ISpRecognizer from sapi.h

  if (g_listening) {
    result->Success(flutter::EncodableValue(true));
    return;
  }

  g_listening = true;

  // Start a background thread that would handle speech recognition
  // For now, we'll note that STT requires Windows 10+ SpeechRecognizer API
  OutputDebugStringA("[PrimeVoice] STT: Listening started (simulated)\n");

  // Notify Flutter
  SendEvent("onSpeechResult",
            flutter::EncodableValue(flutter::EncodableMap{
                {flutter::EncodableValue("text"),
                 flutter::EncodableValue(std::string(""))},
                {flutter::EncodableValue("confidence"),
                 flutter::EncodableValue(0.0)},
            }));

  result->Success(flutter::EncodableValue(true));
}

void PrimeVoicePlugin::StopListening(
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  g_listening = false;
  OutputDebugStringA("[PrimeVoice] STT: Listening stopped\n");
  result->Success(flutter::EncodableValue(true));
}

void PrimeVoicePlugin::SendEvent(const std::string& method,
                                  flutter::EncodableValue args) {
  if (channel_) {
    channel_->InvokeMethod(method,
                           std::make_unique<flutter::EncodableValue>(args));
  }
}

}  // namespace prime_voice
