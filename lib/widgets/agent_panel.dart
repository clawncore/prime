import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import '../services/state_service.dart';
import '../services/audio_service.dart';

class AgentPanel extends StatelessWidget {
  const AgentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = context.watch<StateService>();
    final agents = stateService.agents;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: PrimeTheme.surface950,
        border: Border(
          right: BorderSide(color: PrimeTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(agents),
          const Divider(height: 1, color: PrimeTheme.border),
          Expanded(
            child: agents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      return _AgentCard(agent: agents[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<Agent> agents) {
    final onlineCount = agents
        .where((a) => a.status == AgentStatus.online || a.status == AgentStatus.busy)
        .length;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 14, color: PrimeTheme.primeBlue),
          const SizedBox(width: 8),
          const Text(
            'AGENTS',
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
              color: PrimeTheme.primeGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$onlineCount/${agents.length}',
              style: const TextStyle(
                color: PrimeTheme.primeGreen,
                fontSize: 8,
                fontWeight: FontWeight.w700,
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
      child: Text(
        'NO AGENTS',
        style: TextStyle(
          color: PrimeTheme.textMuted,
          fontSize: 9,
          letterSpacing: 2,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;

  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(agent.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playClick();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PrimeTheme.surface800,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: PrimeTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    agent.name,
                    style: const TextStyle(
                      color: PrimeTheme.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    agent.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                agent.role,
                style: const TextStyle(
                  color: PrimeTheme.textMuted,
                  fontSize: 8,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              if (agent.currentTask != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: PrimeTheme.primeBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    agent.currentTask!,
                    style: const TextStyle(
                      color: PrimeTheme.primeBlue,
                      fontSize: 7,
                      fontFamily: 'JetBrains Mono',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              _LoadBar(load: agent.load),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(AgentStatus status) {
    switch (status) {
      case AgentStatus.online:
        return PrimeTheme.primeGreen;
      case AgentStatus.busy:
        return PrimeTheme.primeAmber;
      case AgentStatus.error:
        return PrimeTheme.primeRed;
      case AgentStatus.offline:
      default:
        return PrimeTheme.textMuted;
    }
  }
}

class _LoadBar extends StatelessWidget {
  final double load;

  const _LoadBar({required this.load});

  @override
  Widget build(BuildContext context) {
    final color = load > 80
        ? PrimeTheme.primeRed
        : load > 50
            ? PrimeTheme.primeAmber
            : PrimeTheme.primeGreen;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: load / 100,
              backgroundColor: PrimeTheme.surface700,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 2,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${load.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontSize: 7,
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ],
    );
  }
}
