import 'package:flutter/material.dart';
import '../theme/prime_theme.dart';
import '../models/prime_state.dart';
import 'prime_core.dart';

class AgentNetwork extends StatelessWidget {
  final List<Agent> agents;
  final CoreState coreState;

  const AgentNetwork({
    super.key,
    required this.agents,
    required this.coreState,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = agents.where((a) =>
        a.status == AgentStatus.online || a.status == AgentStatus.busy).length;

    return Container(
      decoration: BoxDecoration(
        color: PrimeTheme.bgCard,
        border: Border.all(color: PrimeTheme.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(activeCount),
          const Divider(height: 1, color: PrimeTheme.borderSubtle),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: agents.length,
              itemBuilder: (context, index) => _AgentNode(
                agent: agents[index],
                coreState: coreState,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.hub, size: 12, color: PrimeTheme.primePurple.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text('AGENT NETWORK', style: TextStyle(
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
              color: PrimeTheme.statusOnline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '$activeCount/${agents.length}',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: PrimeTheme.statusOnline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentNode extends StatelessWidget {
  final Agent agent;
  final CoreState coreState;

  const _AgentNode({
    required this.agent,
    required this.coreState,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = agent.status == AgentStatus.online || agent.status == AgentStatus.busy;
    final isBusy = agent.status == AgentStatus.busy;
    final statusColor = _statusColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? PrimeTheme.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? statusColor.withValues(alpha: 0.2)
                : PrimeTheme.borderSubtle.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and status
            Row(
              children: [
                // Status indicator
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4)]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Agent name
                Expanded(
                  child: Text(
                    agent.name,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: isActive ? PrimeTheme.textPrimary : PrimeTheme.textMuted,
                    ),
                  ),
                ),

                // Status label
                Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: statusColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Role
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                agent.role.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 7,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                  color: PrimeTheme.textDim,
                ),
              ),
            ),

            // Load bar (when active)
            if (isActive && agent.load > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value: agent.load / 100,
                          backgroundColor: PrimeTheme.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${agent.load.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 7,
                        fontWeight: FontWeight.w500,
                        color: statusColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Current task (when busy)
            if (isBusy && agent.currentTask != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  agent.currentTask!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 7,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: PrimeTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (agent.status) {
      case AgentStatus.online: return PrimeTheme.statusOnline;
      case AgentStatus.busy: return PrimeTheme.statusBusy;
      case AgentStatus.error: return PrimeTheme.statusError;
      case AgentStatus.offline: return PrimeTheme.statusOffline;
    }
  }

  String _statusLabel() {
    switch (agent.status) {
      case AgentStatus.online: return 'ONLINE';
      case AgentStatus.busy: return 'ACTIVE';
      case AgentStatus.error: return 'ERROR';
      case AgentStatus.offline: return 'IDLE';
    }
  }
}
