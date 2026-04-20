import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../widgets/role_avatar.dart';
import '../../models/staff_model.dart';
import '../../core/dsa/staff_sorter.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    var allStaff = ref.watch(staffProvider);
    
    // DSA INTEGRATION: Use stable Merge Sort for staff availability sorting
    allStaff = StaffSorter.mergeSort(List<StaffModel>.from(allStaff), (a, b) {
      if (a.available && !b.available) return -1;
      if (!a.available && b.available) return 1;
      return a.name.compareTo(b.name);
    });
    
    if (selectedFilter == 'Available') {
      allStaff = allStaff.where((s) => s.available).toList();
    } else if (selectedFilter != 'All') {
      allStaff = allStaff.where((s) => s.role == selectedFilter).toList();
    }

    final availableCount = ref.watch(staffProvider).where((s) => s.available).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Directory')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primary.withOpacity(0.1),
            width: double.infinity,
            child: Text(
              '$availableCount Staff Currently Available',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              textAlign: TextAlign.center,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Doctor'),
                const SizedBox(width: 8),
                _buildFilterChip('Nurse'),
                const SizedBox(width: 8),
                _buildFilterChip('Available'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allStaff.length,
              itemBuilder: (context, index) {
                final staff = allStaff[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: RoleAvatar(name: staff.name, role: staff.role, isAvailable: staff.available),
                    title: Text('${staff.name} (${staff.role})'),
                    subtitle: Text(staff.specialization),
                    trailing: Icon(
                      staff.available ? Icons.check_circle : Icons.do_not_disturb_on,
                      color: staff.available ? AppTheme.stable : AppTheme.critical,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => selectedFilter = label);
      },
    );
  }
}
