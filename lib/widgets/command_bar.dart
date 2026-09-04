import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../services/state_service.dart';
import '../services/voice_service.dart';

class CommandBar extends StatefulWidget {
  const CommandBar({super.key});

  @override
  State<CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<CommandBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<StateService>().sendChatMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  String _getHintText(VoiceState voiceState) {
    switch (voiceState) {
      case VoiceState.listening:
        return 'LISTENING...';
      case VoiceState.processing:
        return 'PRIME IS THINKING...';
      case VoiceState.speaking:
        return 'PRIME IS SPEAKING...';
      default:
        return 'TALK TO PRIME...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = context.watch<StateService>().voiceState;
    final voiceEnabled = context.watch<StateService>().voiceEnabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        border: Border.all(color: PrimeTheme.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Mic button
          GestureDetector(
            onTap: () => context.read<StateService>().toggleListening(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: voiceState == VoiceState.listening
                    ? PrimeTheme.primeCyan.withValues(alpha: 0.15)
                    : PrimeTheme.bgElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: voiceState == VoiceState.listening
                      ? PrimeTheme.primeCyan
                      : PrimeTheme.borderDefault,
                ),
              ),
              child: Icon(
                voiceState == VoiceState.listening ? Icons.mic : Icons.mic_none,
                size: 14,
                color: voiceState == VoiceState.listening
                    ? PrimeTheme.primeCyan
                    : PrimeTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Voice state indicator
          if (voiceState != VoiceState.idle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: PrimeTheme.primeCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                voiceState.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: PrimeTheme.primeCyan,
                  letterSpacing: 1.0,
                ),
              ),
            ),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _send(),
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                color: PrimeTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _getHintText(voiceState),
                hintStyle: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: PrimeTheme.textDim,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          // Send button
          GestureDetector(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PrimeTheme.primeCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: PrimeTheme.primeCyan.withValues(alpha: 0.2)),
              ),
              child: Text(
                'SEND',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: PrimeTheme.primeCyan,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
