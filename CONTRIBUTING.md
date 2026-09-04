# Contributing to PRIME

## Cross-Platform Architecture

PRIME is built with Flutter/Dart — **one codebase, all platforms**.

### The Golden Rule

> **If it's in `lib/`, it runs everywhere.**
> If it's platform-specific, it lives in a platform directory.

---

## Directory Structure

```
lib/                          ← SHARED CODE (runs on ALL platforms)
├── brain/                    ← LLM logic, reasoning, providers
├── config/                   ← App identity, constants
├── engine/                   ← Conversation engine
├── models/                   ← Data models (PrimeState, Agent, etc.)
├── providers/                ← Provider factory, STT providers
├── screens/                  ← UI screens
├── services/                 ← State, settings, audio, voice, debug
├── theme/                    ← Colors, typography
├── voice/                    ← Voice manager, TTS providers
└── widgets/                  ← Reusable UI components

android/                      ← Android-specific (Kotlin/Gradle)
ios/                          ← iOS-specific (Swift/Xcode)
linux/                        ← Linux-specific (CMake)
macos/                        ← macOS-specific (Xcode)
web/                          ← Web-specific (index.html)
windows/                      ← Windows-specific (CMake/MSVC)
```

---

## How to Check if Code is Cross-Platform

### ✅ SAFE — Runs on all platforms

| Pattern | Example |
|---------|---------|
| Dart files in `lib/` | `lib/brain/gemini_provider.dart` |
| `package:flutter/*` imports | `import 'package:flutter/material.dart'` |
| `dart:core`, `dart:async`, `dart:convert` | Standard Dart libraries |
| HTTP requests | `package:http/http.dart` |
| JSON serialization | `dart:convert` jsonEncode/jsonDecode |
| Provider state management | `package:provider/provider.dart` |
| SharedPreferences | `package:shared_preferences/shared_preferences.dart` |

### ⚠️ PLATFORM-SPECIFIC — Requires conditional code

| Pattern | Where it matters |
|---------|-----------------|
| `import 'dart:io'` | ❌ Not available on web |
| `Platform.isWindows` / `Platform.isLinux` | ✅ Use with `if` checks |
| `import 'dart:ui'` | ⚠️ Some APIs differ per platform |
| Native plugins | Each platform needs its own implementation |

### ❌ NEVER DO THIS

```dart
// BAD — Hardcoded path for one OS
final file = File('/home/user/.env');

// GOOD — Use platform-aware paths
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/.env');
```

---

## Platform-Specific Code in PRIME

### TTS (Text-to-Speech)

```
lib/voice/
├── tts_provider.dart          ← Interface (abstract class)
├── sapi_tts_provider.dart     ← Windows SAPI implementation
└── linux_tts_provider.dart    ← Linux espeak-ng implementation
```

**Selection happens at runtime:**
```dart
// lib/voice/voice_manager.dart
if (Platform.isWindows) {
  _ttsProvider = SapiTTSProvider();
} else if (Platform.isLinux || Platform.isMacOS) {
  _ttsProvider = LinuxTTSProvider();
}
```

### Audio

```
lib/services/audio_service.dart     ← Uses just_audio (cross-platform)
lib/services/audio_mixer.dart       ← Pure Dart mixing
```

### Window Management

```
lib/main.dart                       ← Uses window_manager plugin
```
The `window_manager` plugin handles Linux, Windows, macOS, and web.

---

## How to Update Code for All Platforms

### Step 1: Identify the change type

| Change type | What to do |
|-------------|-----------|
| New feature in `lib/` | Just edit — works everywhere |
| New plugin dependency | Check plugin supports your target platforms |
| Platform-specific behavior | Add `if (Platform.isX)` checks |
| New native code | Implement for each platform in `android/`, `ios/`, `linux/`, `windows/` |

### Step 2: Check plugin support

Before adding a new dependency:

```bash
# Check what platforms a plugin supports
flutter pub deps | grep -i "plugin_name"
# Or check pub.dev for platform badges
```

### Step 3: Build for each platform

```bash
# Linux
flutter build linux --debug

# Windows (must run on Windows)
flutter build windows --debug

# macOS (must run on macOS)
flutter build macos --debug

# Web
flutter build web

# Android
flutter build apk --debug

# iOS (must run on macOS with Xcode)
flutter build ios --debug
```

### Step 4: Test platform-specific paths

If your code reads files (like `.env`), test the path resolution:

```dart
// Print where the app is looking
final exePath = Platform.resolvedExecutable;
final exeDir = File(exePath).parent.path;
debugPrint('Executable dir: $exeDir');

// Check .env locations
final locations = [
  '$exeDir${Platform.pathSeparator}.env',
  '${Directory.current.path}${Platform.pathSeparator}.env',
];
for (final path in locations) {
  debugPrint('Checking: $path — exists: ${await File(path).exists()}');
}
```

---

## Common Cross-Platform Issues

### 1. File paths

```dart
// ❌ WRONG — Hardcoded separator
final path = '/home/user/file.txt';

// ✅ CORRECT — Use Platform.pathSeparator
final path = '$dir${Platform.pathSeparator}file.txt';

// ✅ BETTER — Use path package
import 'package:path/path.dart' as p;
final path = p.join(dir, 'file.txt');
```

### 2. Imports

```dart
// ❌ WRONG — dart:io not available on web
import 'dart:io';

// ✅ CORRECT — Conditional import
import 'package:flutter/foundation.dart';
if (kIsWeb) {
  // Web implementation
} else {
  import 'dart:io';
  // Native implementation
}
```

### 3. Plugins that don't support all platforms

```yaml
# pubspec.yaml — check platform support
dependencies:
  some_plugin: ^1.0.0  # Check pub.dev for platform badges
```

If a plugin doesn't support your target platform, you need:
- A fallback implementation
- A platform-specific plugin
- Or skip that feature on unsupported platforms

---

## Build Commands Quick Reference

```bash
# Development (hot reload)
flutter run -d linux      # Linux desktop
flutter run -d windows    # Windows desktop
flutter run -d chrome     # Web browser

# Production builds
flutter build linux --release
flutter build windows --release
flutter build web --release

# Check for issues
flutter analyze
flutter test
```

---

## PRIME-Specific Guidelines

### 1. LLM Code

All LLM logic lives in `lib/brain/`. It's pure Dart + HTTP — fully cross-platform.

```bash
# Test LLM independently
curl -s "https://generativelanguage.googleapis.com/v1/models/gemini-3.6-flash:generateContent?key=YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

### 2. UI Code

All UI lives in `lib/widgets/` and `lib/screens/`. Uses Flutter widgets — fully cross-platform.

If you need platform-specific styling:
```dart
import 'package:flutter/foundation.dart';

// Use kIsWeb to check for web platform
if (kIsWeb) {
  // Web-specific styling
} else {
  // Desktop styling
}
```

### 3. Configuration

`.env` file is loaded at runtime from multiple locations. Never hardcode paths.

### 4. Audio

Audio uses `just_audio` (cross-platform). TTS has platform-specific implementations.

---

## Testing Checklist

Before pushing changes:

- [ ] `flutter analyze` — no warnings
- [ ] `flutter test` — all tests pass
- [ ] `flutter build linux --debug` — Linux builds
- [ ] Manual test on Linux — UI looks correct
- [ ] Manual test on Windows — UI looks correct (if available)
- [ ] Check `.env` loading works on both platforms
- [ ] Verify TTS works on target platform

---

## Quick Commands

```bash
# Full rebuild (Linux)
pkill -f prime_flutter 2>/dev/null
flutter build linux --debug
/home/clawncore/prime/build/linux/x64/debug/bundle/prime_flutter &

# Check logs
cat /tmp/prime.log | grep -E "Pipeline|Gemini|ERROR"

# Push to GitHub
git add -A
git commit -m "description"
git push origin main
```
