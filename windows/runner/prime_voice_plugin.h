#ifndef FLUTTER_PLUGIN_PRIME_VOICE_PLUGIN_H_
#define FLUTTER_PLUGIN_PRIME_VOICE_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>
#include <functional>

namespace prime_voice {

class PrimeVoicePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  PrimeVoicePlugin();

  virtual ~PrimeVoicePlugin();

  // Disallow copy and assign.
  PrimeVoicePlugin(const PrimeVoicePlugin&) = delete;
  PrimeVoicePlugin& operator=(const PrimeVoicePlugin&) = delete;

 private:
  // Called from Flutter when method channel is invoked.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // TTS methods
  void Speak(const std::string& text,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StopSpeaking(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void IsTtsAvailable(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // STT methods
  void StartListening(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StopListening(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void IsSttAvailable(
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Send events back to Flutter
  void SendEvent(const std::string& method, flutter::EncodableValue args);

  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  // SAPI pointers (opaque)
  void* tts_voice_ = nullptr;
  void* stt_engine_ = nullptr;
  bool tts_initialized_ = false;
  bool stt_initialized_ = false;
};

}  // namespace prime_voice

#endif  // FLUTTER_PLUGIN_PRIME_VOICE_PLUGIN_H_
