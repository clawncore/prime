import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';

class ConversationPanel extends StatefulWidget {
  const ConversationPanel({super.key});

  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<StateService>().sendChatMessage(text);
    _controller.clear();
    _focusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final conversation = stateService.conversation;

    return Container(
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: PrimeTheme.border),
          Expanded(
            child: conversation.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: conversation.length,
                    itemBuilder: (context, index) {
                      final msg = conversation[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
          const Divider(height: 1, color: PrimeTheme.border),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 14, color: PrimeTheme.primeCyan),
          SizedBox(width: 8),
          Text(
            'CONVERSATION',
            style: TextStyle(
              color: PrimeTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 32, color: PrimeTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'START A CONVERSATION',
            style: TextStyle(
              color: PrimeTheme.textMuted,
              fontSize: 10,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Type a message below to begin',
            style: TextStyle(
              color: PrimeTheme.textMuted,
              fontSize: 9,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: PrimeTheme.surface900,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: PrimeTheme.textPrimary,
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
              ),
              decoration: InputDecoration(
                hintText: 'Enter command or message...',
                hintStyle: const TextStyle(
                  color: PrimeTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'JetBrains Mono',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: PrimeTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: PrimeTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                      color: PrimeTheme.primeCyan, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onTap: _sendMessage),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PrimeTheme.primeCyan.withValues(alpha: 0.15),
                border: Border.all(
                  color: PrimeTheme.primeCyan.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  '◈',
                  style: TextStyle(
                    color: PrimeTheme.primeCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser
                    ? PrimeTheme.primeCyan.withValues(alpha: 0.1)
                    : PrimeTheme.surface800,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUser
                      ? PrimeTheme.primeCyan.withValues(alpha: 0.2)
                      : PrimeTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'YOU' : 'PRIME',
                    style: TextStyle(
                      color: isUser
                          ? PrimeTheme.primeCyan
                          : PrimeTheme.primeBlue,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: PrimeTheme.textPrimary,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: PrimeTheme.textMuted,
                      fontSize: 8,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PrimeTheme.primeGreen.withValues(alpha: 0.15),
                border: Border.all(
                  color: PrimeTheme.primeGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: PrimeTheme.primeGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playClick();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PrimeTheme.primeCyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: PrimeTheme.primeCyan.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            Icons.send,
            size: 14,
            color: PrimeTheme.primeCyan,
          ),
        ),
      ),
    );
  }
}
