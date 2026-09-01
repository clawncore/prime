import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/voice_service.dart';

class JarvisHud extends StatefulWidget {
  const JarvisHud({super.key});

  @override
  State<JarvisHud> createState() => _JarvisHudState();
}

class _JarvisHudState extends State<JarvisHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendCommand() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    context.read<StateService>().handleVoiceCommand(text);
    _inputController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final voiceState = stateService.voiceState;
    final lastCommand = stateService.lastCommand;
    final lastResponse = stateService.lastResponse;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: PrimeTheme.surface900,
        border: Border(
          top: BorderSide(color: PrimeTheme.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusBar(voiceState),
          const SizedBox(height: 8),
          _buildInputArea(voiceState, lastCommand, lastResponse),
          const SizedBox(height: 8),
          _buildControlBar(stateService, voiceState),
        ],
      ),
    );
  }

  Widget _buildStatusBar(VoiceState voiceState) {
    final color = _stateColor(voiceState);

    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final glow = voiceState == VoiceState.speaking
                ? 0.7 + _pulseController.value * 0.3
                : voiceState == VoiceState.listening
                    ? 0.5 + _pulseController.value * 0.5
                    : 0.3;
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: glow),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow * 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          _stateLabel(voiceState),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const Spacer(),
        Text(
          'J.A.R.V.I.S. INTERFACE',
          style: TextStyle(
            color: PrimeTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(VoiceState voiceState, String lastCommand, String lastResponse) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PrimeTheme.surface800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: voiceState == VoiceState.speaking
              ? PrimeTheme.primeGreen.withValues(alpha: 0.5)
              : PrimeTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show last exchange
          if (lastCommand.isNotEmpty || lastResponse.isNotEmpty) ...[
            if (lastCommand.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('YOU: ', style: TextStyle(
                      color: PrimeTheme.primeCyan,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    )),
                    Expanded(
                      child: Text(
                        lastCommand,
                        style: const TextStyle(
                          color: PrimeTheme.textPrimary,
                          fontSize: 9,
                          fontFamily: 'JetBrains Mono',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (lastResponse.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('PRIME: ', style: TextStyle(
                      color: PrimeTheme.primeGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    )),
                    Expanded(
                      child: Text(
                        lastResponse,
                        style: const TextStyle(
                          color: PrimeTheme.textSecondary,
                          fontSize: 9,
                          fontFamily: 'JetBrains Mono',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ],
          // Input field
          Row(
            children: [
              if (voiceState == VoiceState.speaking)
                _buildWaveform()
              else
                const Icon(Icons.keyboard, size: 14, color: PrimeTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: PrimeTheme.textPrimary,
                    fontSize: 11,
                    fontFamily: 'JetBrains Mono',
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type command or speak...',
                    hintStyle: TextStyle(
                      color: PrimeTheme.textMuted,
                      fontSize: 10,
                      fontFamily: 'JetBrains Mono',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onSubmitted: (_) => _sendCommand(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _sendCommand,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: PrimeTheme.primeCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: PrimeTheme.primeCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 12,
                      color: PrimeTheme.primeCyan,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    final barCount = 8;
    final color = PrimeTheme.primeGreen;

    return SizedBox(
      width: 30,
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final rng = math.Random(i + DateTime.now().millisecond ~/ 100);
          final height = 3.0 + rng.nextDouble() * 13.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 2,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6 + rng.nextDouble() * 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControlBar(StateService stateService, VoiceState voiceState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          icon: Icons.mic,
          label: voiceState == VoiceState.listening ? 'STOP' : 'LISTEN',
          color: voiceState == VoiceState.listening
              ? PrimeTheme.primeRed
              : PrimeTheme.primeCyan,
          onTap: () => stateService.toggleListening(),
          isActive: voiceState == VoiceState.listening,
        ),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.stop_circle,
          label: 'STOP',
          color: PrimeTheme.primeAmber,
          onTap: () => stateService.voice.stopSpeaking(),
          isActive: voiceState == VoiceState.speaking,
        ),
        const SizedBox(width: 12),
        _ControlButton(
          icon: Icons.volume_up,
          label: 'SPEAK TEST',
          color: PrimeTheme.primeGreen,
          onTap: () => stateService.handleVoiceCommand('hello'),
          isActive: false,
        ),
      ],
    );
  }

  String _stateLabel(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return 'VOICE: ACTIVE';
      case VoiceState.speaking:
        return 'VOICE: SPEAKING';
      case VoiceState.processing:
        return 'VOICE: PROCESSING';
      case VoiceState.error:
        return 'VOICE: ERROR';
      case VoiceState.idle:
      default:
        return 'VOICE: STANDBY';
    }
  }

  Color _stateColor(VoiceState state) {
    switch (state) {
      case VoiceState.listening:
        return PrimeTheme.primeCyan;
      case VoiceState.speaking:
        return PrimeTheme.primeGreen;
      case VoiceState.processing:
        return PrimeTheme.primeBlue;
      case VoiceState.error:
        return PrimeTheme.primeRed;
      case VoiceState.idle:
      default:
        return PrimeTheme.textMuted;
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : PrimeTheme.surface800,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.5)
                  : PrimeTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
