import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/dsa/alert_priority_queue.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import 'widgets/alert_card.dart';
import '../../models/alert_model.dart';
import '../../providers/session_provider.dart';

class AlertListScreen extends ConsumerStatefulWidget {
  const AlertListScreen({super.key});

  @override
  ConsumerState<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends ConsumerState<AlertListScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final allAlerts = ref.watch(alertsProvider);
    
    // Auth role filtering (Mock)
    final currentUser = ref.watch(currentUserProvider);
    List<AlertModel> filteredAlerts = allAlerts;
    if (currentUser?.role == 'Doctor') {
      filteredAlerts = allAlerts.where((a) => a.target == 'All Staff' || a.target == 'Doctors Only').toList();
    } else if (currentUser?.role == 'Nurse') {
      filteredAlerts = allAlerts.where((a) => a.target == 'All Staff' || a.target == 'Nurses Only').toList();
    }

    // Keyword filtering
    if (selectedFilter != 'All') {
      filteredAlerts = filteredAlerts.where((a) => a.severity == selectedFilter.toUpperCase()).toList();
    }

    // DSA INTEGRATION: Use Min-Heap based Priority Queue for sorting
    final pq = AlertPriorityQueue();
    for (final a in filteredAlerts) {
      pq.insert(a);
    }
    final sortedAlerts = pq.sorted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Alerts'),
      ),
      body: Container(
        color: AppTheme.background,
        child: Column(
          children: [
            SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Critical', AppTheme.critical),
                const SizedBox(width: 8),
                _buildFilterChip('Urgent', AppTheme.urgent),
                const SizedBox(width: 8),
                _buildFilterChip('Stable', AppTheme.stable),
              ],
            ),
          ),
          Expanded(
            child: sortedAlerts.isEmpty 
              ? const Center(child: Text('No active alerts.'))
              : ListView.builder(
                  itemCount: sortedAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = sortedAlerts[index];
                    return Dismissible(
                      key: Key(alert.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Mock dismiss - ignoring state update for now or could call delete in provider if desired
                      },
                      child: AlertCard(
                        alert: alert,
                        onTap: () => context.push('/alerts/${alert.id}'),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterChip(String label, [Color? color]) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color?.withValues(alpha: 0.2) ?? AppTheme.primary.withValues(alpha: 0.2),
      onSelected: (selected) {
        if (selected) {
          setState(() => selectedFilter = label);
        }
      },
    );
  }
}
