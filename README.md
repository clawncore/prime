# CLAWN PRIME

### Autonomous AI Command Center

A JARVIS-inspired desktop AI command center built with Flutter. Real-time neural brain visualization, voice interaction powered by Google Gemini, full telemetry dashboard, 8 autonomous agents, 16 contextual sound effects, and a dark HUD interface — all running as a native desktop application.

---

## What It Is

CLAWN PRIME is not a chatbot. It is a fully interactive AI command environment — a personal operating system interface where you speak to an intelligent core and it responds, thinks, and acts.

The interface renders a **neural brain visualization** as its centerpiece — a pulsing mesh of nodes, synaptic connections, and data streams that react to voice state, system activity, and mode changes. Around it: real-time telemetry, agent status, activity logs, and a JARVIS-style voice HUD at the bottom.

It connects to a backend server via WebSocket for multi-agent orchestration, but **runs fully standalone** with a local LLM brain (Google Gemini) and Windows SAPI voice.

---

## Features

### Neural Brain Visualization
A 3D-style animated neural mesh rendered with Flutter's `CustomPainter`. 24 nodes with synaptic connections, bezier signal paths, orbiting data particles, a pulsing core orb, and voice-state-reactive arc indicators. The brain shifts color through cyan → blue → purple → amber based on system state.

### Voice Interaction
- **Speech-to-Text**: Click LISTEN, speak naturally, PRIME recognizes via Windows Speech Recognition
- **Text-to-Speech**: PRIME responds with Microsoft Zira Desktop voice via Windows SAPI
- **LLM Brain**: Google Gemini 3.6 Flash processes conversational input with context memory
- **Local Commands**: Deterministic responses for status, hello, capabilities, shutdown — no LLM needed

### Command Center Dashboard
| Panel | Position | Content |
|-------|----------|---------|
| **StatusBar** | Top | Logo, state indicator, core toggle, connection status, mode chip, CPU/MEM/NET readout, mute button |
| **AgentPanel** | Left (220px) | 8 named agents (ALPHA–THETA) with status dots, roles, load bars, current tasks |
| **NeuralBrainVisualization** | Center | Animated neural mesh with core pulse and voice indicator |
| **TelemetryPanel** | Right (200px) | CPU, memory, GPU gauges, network I/O, tokens/sec, total tokens, uptime |
| **ActivityFeed** | Bottom-left | Scrolling event log with severity colors and timestamps |
| **Transcript** | Bottom-right | Conversation history with user/AI message pairs |
| **JarvisHud** | Bottom bar | Voice status, text input, LISTEN/STOP/SPEAK controls, waveform visualization |
| **HudOverlay** | Full-screen | Corner brackets, vertical scan line, falling data streams |
| **MiniBar** | Bottom-left float | Draggable pill with expandable quick actions |

### 8 Autonomous Agents
| Agent | Role |
|-------|------|
| ALPHA | Task Orchestrator |
| BETA | Code Analysis |
| GAMMA | Memory & Context |
| DELTA | Web Intelligence |
| EPSILON | File Operations |
| ZETA | Security Monitor |
| ETA | Performance Tuner |
| THETA | Data Synthesis |

### 6 System Modes
| Mode | Color | Sound | Behavior |
|------|-------|-------|----------|
| Standard | Green/Blue | — | Normal operations |
| Stealth | Purple | Wake notification | Reduced footprint |
| Combat | Red | Warning | Maximum capacity |
| Diagnostic | Cyan | Notification | System analysis |
| Sleep | Amber | Sleep notification | Standby with voice monitoring |
| Offline | Gray | — | Core shutdown |

### 16 Contextual Sound Effects
Every interaction has audio feedback:

| Category | Sounds |
|----------|--------|
| **Startup** | Boot sound |
| **Wake** | Wake notification, wake from sleep |
| **Processing** | Analysing |
| **Response** | Reply (before TTS), affirmation |
| **Alerts** | Positive result, negative result, warning, malfunction |
| **UI** | Click, click secondary, zoom in, zoom out |
| **Power** | Sleep notification |
| **General** | Notification |

### Boot Sequence
A cinematic 6-step initialization with animated progress:
1. INITIALIZING PRIME...
2. LOADING CORE MODULES...
3. CONNECTING NEURAL MESH...
4. CALIBRATING SENSORS...
5. CHECKING AGENT STATUS...
6. CORE ONLINE

Each step plays a notification sound. The neural brain comes online with frequency and activity readouts. Voice system activates automatically.

---

## Architecture

### Provider System (Swappable)

The brain and voice layers use abstract interfaces so implementations can be swapped without touching the rest of the codebase:

```
┌─────────────────────────────────────────────┐
│                 VoiceManager                 │
│         (routes input, coordinates)          │
├──────────────────┬──────────────────────────┤
│   Brain Layer    │      Voice Layer          │
│  (WHAT to say)   │     (HOW it sounds)       │
├──────────────────┼──────────────────────────┤
│  LLMProvider     │     TTSProvider           │
│  ┌────────────┐  │     ┌──────────────────┐  │
│  │ Gemini     │  │     │ SapiTTS          │  │
│  │ Provider   │  │     │ Provider         │  │
│  └────────────┘  │     └──────────────────┘  │
└──────────────────┴──────────────────────────┘
```

**Rule**: The brain must NOT directly control audio, visuals, or system commands. The voice layer must NOT know which LLM generated the text.

### Data Flow

```
User Input (text or speech)
    │
    ▼
VoiceManager.processInput()
    │
    ├── Local Command? → Deterministic Response
    │
    └── Conversation? → GeminiProvider.generate()
                            │
                            ▼
                     LLMResponse (text)
                            │
                            ▼
                     TTSProvider.speak()
                            │
                            ▼
                     Audio + UI Update
```

### State Management

Pure `ChangeNotifierProvider` pattern:
- `StateService` extends `ChangeNotifier` — single source of truth
- `PrimeState` is immutable with `copyWith()` — every update creates a new instance
- All UI widgets use `context.watch<StateService>()` to rebuild on changes
- Streams for real-time data (WebSocket, voice)
- Timers for polling (telemetry 2s, state 10s)

### Service Map

| Service | Type | Responsibility |
|---------|------|----------------|
| `StateService` | ChangeNotifier | Central state, boot sequence, command routing, WebSocket events, API polling |
| `AudioService` | Singleton | 16 sound effects, mute/volume, audioplayers |
| `VoiceService` | Singleton | Windows SAPI TTS + speech recognition via PowerShell |
| `VoiceManager` | Singleton | Routes input to brain or local commands, coordinates TTS output |
| `ApiService` | Singleton | HTTP REST client (backend at localhost:4000) |
| `WebSocketService` | Singleton | WebSocket client with auto-reconnect, event broadcasting |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.47+ / Dart 3.13+ |
| State | Provider (ChangeNotifier) |
| LLM | Google Gemini 3.6 Flash (REST API) |
| TTS | Windows SAPI via PowerShell |
| STT | Windows Speech Recognition via PowerShell |
| Audio | audioplayers package |
| Visualization | CustomPainter (neural mesh, HUD overlay) |
| Backend | WebSocket + REST (localhost:4000) |
| Window | window_manager (1400x900, frameless) |

---

## Project Structure

```
prime_flutter/
├── lib/
│   ├── main.dart                          # Entry point, window config, providers
│   │
│   ├── brain/                             # LLM integration layer
│   │   ├── llm_provider.dart              # Abstract LLM interface
│   │   ├── gemini_provider.dart           # Google Gemini implementation
│   │   └── conversation_manager.dart      # Context window, token estimation
│   │
│   ├── voice/                             # TTS integration layer
│   │   ├── tts_provider.dart              # Abstract TTS interface
│   │   ├── sapi_tts_provider.dart         # Windows SAPI implementation
│   │   └── voice_manager.dart             # Brain + voice coordinator
│   │
│   ├── services/                          # Core services
│   │   ├── state_service.dart             # Central nervous system
│   │   ├── voice_service.dart             # Voice I/O (SAPI TTS + STT)
│   │   ├── audio_service.dart             # 16 sound effects
│   │   ├── api_service.dart               # HTTP client
│   │   └── websocket_service.dart         # WebSocket client
│   │
│   ├── screens/
│   │   ├── splash_screen.dart             # 6-step boot animation
│   │   └── command_center.dart            # Main dashboard layout
│   │
│   ├── widgets/
│   │   ├── neural_brain_visualization.dart # Animated neural mesh (CustomPainter)
│   │   ├── jarvis_hud.dart                # Voice/text input HUD
│   │   ├── status_bar.dart                # Top status bar
│   │   ├── agent_panel.dart               # 8 agent cards
│   │   ├── telemetry_panel.dart           # System metrics
│   │   ├── activity_feed.dart             # Event log
│   │   ├── hud_overlay.dart               # Corner brackets + scan line
│   │   ├── mini_bar.dart                  # Draggable floating widget
│   │   ├── prime_core_visualization.dart  # Alternative core viz (unused)
│   │   └── conversation_panel.dart        # Standalone chat (unused)
│   │
│   ├── models/
│   │   └── prime_state.dart               # All data models
│   │
│   └── theme/
│       └── prime_theme.dart               # Dark theme, color palette
│
├── assets/audio/prime/                    # 16 SFX files
│   ├── startup/start.mp3
│   ├── wake/
│   ├── processing/
│   ├── response/
│   ├── alerts/
│   ├── ui/
│   └── power/
│
├── pubspec.yaml
├── .env.example
└── linux/ windows/ web/                   # Platform runners
```

**26 Dart files · ~6,200 lines of code**

---

## Getting Started

### Prerequisites

- **Flutter** 3.47+ (`flutter doctor` should pass)
- **Dart** 3.13+
- **Platform tools**: Android Studio / Xcode / Visual Studio (depending on target)
- **Gemini API key** from [Google AI Studio](https://aistudio.google.com/apikey)

### Quick Start

```bash
# Clone
git clone https://github.com/clawncore/prime.git
cd prime

# Install dependencies
flutter pub get

# Configure API key
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY

# Run
flutter run -d linux      # Linux
flutter run -d macos      # macOS
flutter run -d windows    # Windows
```

### Environment Variables

Create a `.env` file in the project root (or next to the built executable):

```env
GEMINI_API_KEY=your_api_key_here
GEMINI_MODEL=gemini-3.6-flash
TTS_PROVIDER=sapi
SAPI_VOICE=Microsoft Zira Desktop
SAPI_RATE=1.0
SAPI_VOLUME=1.0
```

---

## Building for Production

### Linux
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
# Copy the entire bundle to target machine
```

### macOS
```bash
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Windows
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
# Copy the ENTIRE directory (exe + DLLs + data/)
```

---

## Platform Notes

### Windows (Current Default)
- TTS: Windows SAPI via PowerShell (Zira Desktop voice)
- STT: Windows Speech Recognition via PowerShell
- All features fully functional

### Linux
- TTS: Use `flutter_tts` package (speech-dispatcher backend)
- STT: Use `speech_to_text` package (PulseAudio/PipeWire)
- Required: `sudo apt install speech-dispatcher libspeechd-dev`
- See `CONTRIBUTING.md` for adaptation guide

### macOS
- TTS: Use `flutter_tts` package (NSSpeechSynthesizer)
- STT: Use `speech_to_text` package (NSSpeechRecognizer)
- Grant microphone permission in System Preferences

---

## Extending

### Adding a New LLM Provider

1. Create `lib/brain/my_provider.dart`
2. Implement the `LLMProvider` interface
3. Update `VoiceManager` to instantiate it

```dart
class MyProvider implements LLMProvider {
  @override
  String get name => 'My LLM';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<LLMResponse> generate({
    required String userMessage,
    required List<ConversationTurn> context,
    String? systemPrompt,
  }) async {
    // Call your LLM API here
    return LLMResponse(text: 'Response', type: ResponseType.conversation);
  }
}
```

### Adding a New TTS Provider

1. Create `lib/voice/my_tts_provider.dart`
2. Implement the `TTSProvider` interface
3. Update `VoiceManager` to use it

---

## Backend (Optional)

PRIME works standalone, but connects to a backend for multi-agent features:

- **REST API**: `http://localhost:4000`
- **WebSocket**: `ws://localhost:4000`
- Backend source: `prime/apps/server/` (separate project)

The backend requires an `OPENROUTER_API_KEY` in its `.env` file.

---

## License

Private project. All rights reserved.

---

Built with Flutter. Designed as a command center, not just an app.
