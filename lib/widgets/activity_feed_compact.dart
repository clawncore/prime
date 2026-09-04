import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';

class ActivityFeedCompact extends StatelessWidget {
  final List<ActivityEvent> feed;

  const ActivityFeedCompact({
    super.key,
    required this.feed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        border: Border.all(color: PrimeTheme.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: PrimeTheme.borderSubtle),
          Expanded(
            child: feed.isEmpty
                ? Center(
                    child: Text('No activity', style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      color: PrimeTheme.textDim,
                    )),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: feed.length.clamp(0, 20),
                    itemBuilder: (context, index) {
                      final event = feed[index];
                      final isLast = index == feed.length - 1 || index >= 19;
                      return _TimelineItem(event: event, isLast: isLast);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.timeline, size: 12, color: PrimeTheme.primeBlue.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text('ACTIVITY TIMELINE', style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: PrimeTheme.textSecondary,
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: PrimeTheme.primeBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${feed.length}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: PrimeTheme.primeBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ActivityEvent event;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = PrimeTheme.severityColor(event.severity);
    final time = '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}';
    final component = _extractComponent(event.message);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 16,
            child: Column(
              children: [
                // Status dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: PrimeTheme.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event message
                  Text(
                    event.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: PrimeTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Component and timestamp row
                  Row(
                    children: [
                      if (component.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: PrimeTheme.bgElevated,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            component.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 7,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                              color: PrimeTheme.textDim,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(time, style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 7,
                        fontWeight: FontWeight.w400,
                        color: PrimeTheme.textDim,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractComponent(String message) {
    // Try to extract component name from common patterns
    final lower = message.toLowerCase();
    if (lower.contains('voice') || lower.contains('tts') || lower.contains('stt')) return 'VOICE';
    if (lower.contains('websocket') || lower.contains('ws') || lower.contains('connection')) return 'NETWORK';
    if (lower.contains('agent')) return 'AGENT';
    if (lower.contains('core') || lower.contains('prime')) return 'CORE';
    if (lower.contains('error') || lower.contains('failed')) return 'ERROR';
    return '';
  }
}
