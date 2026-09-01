import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final feed = stateService.activityFeed;

    return Container(
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
      ),
      child: Column(
        children: [
          _buildHeader(feed),
          const Divider(height: 1, color: PrimeTheme.border),
          Expanded(
            child: feed.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: feed.length,
                    itemBuilder: (context, index) {
                      final event = feed[index];
                      return _ActivityItem(event: event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<ActivityEvent> feed) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, size: 14, color: PrimeTheme.primeAmber),
          const SizedBox(width: 8),
          const Text(
            'ACTIVITY',
            style: TextStyle(
              color: PrimeTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: PrimeTheme.surface800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${feed.length}',
              style: const TextStyle(
                color: PrimeTheme.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrains Mono',
              ),
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
          Icon(Icons.hourglass_empty, size: 24, color: PrimeTheme.textMuted),
          SizedBox(height: 8),
          Text(
            'NO ACTIVITY',
            style: TextStyle(
              color: PrimeTheme.textMuted,
              fontSize: 9,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityEvent event;

  const _ActivityItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = PrimeTheme.severityColor(event.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: PrimeTheme.surface800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PrimeTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.message,
                  style: const TextStyle(
                    color: PrimeTheme.textPrimary,
                    fontSize: 9,
                    fontFamily: 'JetBrains Mono',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      event.type.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(event.timestamp),
                      style: const TextStyle(
                        color: PrimeTheme.textMuted,
                        fontSize: 7,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
