# PRIME Debugging Guide

## Quick Health Check

```bash
# Is the app running?
ps aux | grep prime_flutter | grep -v grep

# Kill all instances
pkill -f prime_flutter

# Run with logs captured
/home/clawncore/prime/build/linux/x64/debug/bundle/prime_flutter > /tmp/prime.log 2>&1 &
sleep 4 && cat /tmp/prime.log
```

## Architecture Overview

```
User types message
       ↓
StateService.sendChatMessage()
       ↓
VoiceManager.processInput()
       ↓
ReasoningPipeline.execute()     ← Single LLM call, streaming
       ↓
GeminiProvider.streamGenerate() ← HTTP POST to Gemini API (SSE stream)
       ↓
Tokens arrive → chunkController → UI renders progressively
       ↓
Response complete → finalizeStreamingMessage()
       ↓
TTS (non-blocking, fire-and-forget)
```

**Key files:**
- `lib/services/state_service.dart` — App state, sendChatMessage, streaming
- `lib/voice/voice_manager.dart` — LLM routing, TTS
- `lib/brain/reasoning_pipeline.dart` — Pipeline orchestration
- `lib/brain/gemini_provider.dart` — Gemini API calls (streaming + non-streaming)
- `lib/widgets/conversation_panel.dart` — Chat UI with streaming cursor
- `lib/config/prime_identity.dart` — System prompt

## Test the Gemini API Directly

```bash
# Get the API key
grep GEMINI_API_KEY /home/clawncore/prime/.env | cut -d= -f2

# Test non-streaming
curl -s "https://generativelanguage.googleapis.com/v1/models/gemini-3.6-flash:generateContent?key=$(grep GEMINI_API_KEY /home/clawncore/prime/.env | cut -d= -f2)" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}],"generationConfig":{"maxOutputTokens":100}}'

# Test streaming
curl -s "https://generativelanguage.googleapis.com/v1/models/gemini-3.6-flash:streamGenerateContent?alt=sse&key=$(grep GEMINI_API_KEY /home/clawncore/prime/.env | cut -d= -f2)" \
  -H 'Content-Type: application/json' \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}],"generationConfig":{"maxOutputTokens":100}}'
```

## Read Live Logs

```bash
# Watch all pipeline activity
tail -f /tmp/prime.log | grep -E "Pipeline|Gemini|ERROR|REQ-|STREAM"

# Watch only errors
tail -f /tmp/prime.log | grep -i "error"

# Watch timing
tail -f /tmp/prime.log | grep -E "FIRST TOKEN|STREAM COMPLETE|TOTAL|RESPONSE"

# Watch everything
tail -f /tmp/prime.log
```

## Log Format

Every log line has a correlation ID for tracing:

```
[Pipeline][REQ-MTMG13BC] START — input="hello"
[Pipeline][REQ-MTMG13BC] CONTEXT — 0ms, turns=1
[Pipeline][REQ-MTMG13BC] LLM REQUEST — promptChars=39
[Gemini][G13BG] REQUEST START — model=gemini-3.6-flash, messages=3
[Gemini][G13BG] STREAM CONNECTED — 850ms
[Gemini][G13BG] FIRST TOKEN — 1200ms
[Gemini][G13BG] STREAM COMPLETE — chunks=45, chars=312, time=3800ms
[Pipeline][REQ-MTMG13BC] LLM COMPLETE — time=3850ms, chars=312, words=48
[Pipeline][REQ-MTMG13BC] TOTAL — 3860ms
```

**What each line means:**
- `REQ-XXXXX` — Unique request ID (same ID = same user message)
- `Gemini][XXXX` — Gemini API-level event
- `FIRST TOKEN` — Time to first token (TTFT) — key latency metric
- `STREAM COMPLETE` — All tokens received
- `TOTAL` — End-to-end pipeline time

## Common Issues

### 1. "I encountered an error processing your request"

```bash
# Check the actual error
grep -A5 "LLM ERROR\|API ERROR\|TIMEOUT\|FAILED" /tmp/prime.log

# Common causes:
# - Invalid API key → test with curl above
# - Model not found → check .env GEMINI_MODEL=gemini-3.6-flash
# - Network timeout → check internet connection
# - Rate limiting → wait and retry
```

### 2. Response takes >10 seconds

```bash
# Check TTFT (time to first token)
grep "FIRST TOKEN" /tmp/prime.log | tail -5

# If TTFT is high:
# - Network latency to Google servers
# - Large prompt (too much conversation history)
# - Gemini cold start (first request is slower)

# Check prompt size
grep "promptChars" /tmp/prime.log | tail -5
```

### 3. Response is truncated

```bash
# Check maxOutputTokens setting
grep "maxOutputTokens" /home/clawncore/prime/lib/brain/gemini_provider.dart

# Should be 4096. If it's 256, responses are cut off at ~190 words.
```

### 4. Streaming doesn't work (all text appears at once)

```bash
# Check if streaming is being used
grep "USING STREAMING\|USING NON-STREAMING" /tmp/prime.log

# If NON-STREAMING:
# - supportsStreaming returns false
# - Check lib/brain/gemini_provider.dart line: bool get supportsStreaming => true;
```

### 5. App crashes on startup

```bash
# Check for initialization errors
grep -E "ERROR|error|FAILED|failed|Exception" /tmp/prime.log | head -20

# Common causes:
# - .env not found → check all 3 locations:
#   1. Next to executable
#   2. /home/clawncore/prime/.env
#   3. Current working directory
```

### 6. TTS not working

```bash
# Check TTS initialization
grep "LinuxTTS\|SapiTTS\|TTS" /tmp/prime.log

# Linux: requires espeak-ng
which espeak-ng || sudo apt install espeak-ng

# Windows: uses built-in SAPI (no install needed)
```

## Rebuild and Test

```bash
# Kill old instance
pkill -f prime_flutter

# Rebuild
flutter build linux --debug

# Run
/home/clawncore/prime/build/linux/x64/debug/bundle/prime_flutter > /tmp/prime.log 2>&1 &

# Wait for init
sleep 4

# Verify LLM is enabled
grep "LLM enabled" /tmp/prime.log
# Should show: [VoiceManager] LLM enabled: Gemini (gemini-3.6-flash)

# Send a test message via the UI and watch logs
tail -f /tmp/prime.log | grep -E "Pipeline|Gemini|FIRST|COMPLETE|ERROR"
```

## Performance Targets

| Metric | Target | How to check |
|--------|--------|-------------|
| App startup | <2s | `grep "LLM enabled" /tmp/prime.log` |
| Time to first token | <3s | `grep "FIRST TOKEN" /tmp/prime.log` |
| Total response (simple) | <5s | `grep "TOTAL" /tmp/prime.log` |
| Total response (complex) | <10s | `grep "TOTAL" /tmp/prime.log` |
| No truncation | full response | Check response chars/words match UI |

## Key Configuration

```bash
# .env file
cat /home/clawncore/prime/.env

# Should contain:
# GEMINI_API_KEY=your_key_here
# GEMINI_MODEL=gemini-3.6-flash

# maxOutputTokens (in gemini_provider.dart)
grep "maxOutputTokens" /home/clawncore/prime/lib/brain/gemini_provider.dart
# Should be 4096

# HTTP timeout (in gemini_provider.dart)
grep "Duration(seconds:" /home/clawncore/prime/lib/brain/gemini_provider.dart
# Should be 60
```

## If You Need to Fix Something

1. **Read the error first:** `grep ERROR /tmp/prime.log`
2. **Trace the request:** `grep REQ-XXXXX /tmp/prime.log`
3. **Check the file:** Read the relevant `.dart` file
4. **Fix and rebuild:** `flutter build linux --debug`
5. **Test:** Run and send a message
6. **Verify:** Check logs for expected timing
7. **Push:** `git add -A && git commit -m "fix: description" && git push origin main`
