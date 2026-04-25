import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../models/bed_model.dart';
import '../../providers/firestore_providers.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'widgets/bed_card.dart';

class BedTrackerScreen extends ConsumerStatefulWidget {
  const BedTrackerScreen({super.key});

  @override
  ConsumerState<BedTrackerScreen> createState() => _BedTrackerScreenState();
}

class _BedTrackerScreenState extends ConsumerState<BedTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showStatusUpdateSheet(BuildContext context, BedModel bed) {
    String newId = bed.id;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(builder: (ctx, setSheetState) {
              return SafeArea(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Manage Bed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: AppTheme.critical),
                            onPressed: () => _confirmDelete(bed),
                          ),
                        ],
                      ),
                      const Gap(8),
                      const Text('Update bed identity or clinical status.', style: TextStyle(color: AppTheme.textSecondary)),
                      const Gap(24),
                      
                      const Text('Rename Bed ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                      const Gap(8),
                      TextField(
                        controller: TextEditingController(text: newId)..selection = TextSelection.collapsed(offset: newId.length),
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(hintText: 'Enter New Bed ID'),
                        onChanged: (v) => newId = v,
                      ),
                      const Gap(12),
                      ElevatedButton(
                        onPressed: () async {
                          final finalNewId = newId.trim().toUpperCase();
                          if (finalNewId.isNotEmpty && finalNewId != bed.id) {
                            final existingBeds = ref.read(realBedsProvider).asData?.value ?? [];
                            bool exists = existingBeds.any((b) => b.id == finalNewId);
                            
                            if (exists) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.critical, content: Text('Bed ID "$finalNewId" already exists!')));
                              return;
                            }

                            // Rename logic: Delete old, add new
                            final renamedBed = bed.copyWith(id: finalNewId);
                            await ref.read(firestoreServiceProvider).addBed(renamedBed);
                            await ref.read(firestoreServiceProvider).deleteBed(bed.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text('Update Bed ID'),
                      ),

                      const Gap(32),
                      const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                      const Gap(12),
                      _buildStatusButton('Available', AppTheme.stable, Icons.check_circle_outline, () {
                        ref.read(firestoreServiceProvider).updateBedStatus(bed.id, 'Available', patientId: null, patientName: null);
                        Navigator.pop(context);
                      }),
                      const Gap(12),
                      _buildStatusButton('Occupied', AppTheme.critical, Icons.do_not_disturb_on, () {
                        ref.read(firestoreServiceProvider).updateBedStatus(bed.id, 'Occupied');
                        Navigator.pop(context);
                      }),
                      const Gap(12),
                      _buildStatusButton('Maintenance', Colors.orange, Icons.build_outlined, () {
                        ref.read(firestoreServiceProvider).updateBedStatus(bed.id, 'Maintenance');
                        Navigator.pop(context);
                      }),
                      const Gap(24),
                    ],
                  ),
                ),
              );
            });
          }
        );
      },
    );
  }

  void _confirmDelete(BedModel bed) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Bed?'),
        content: Text('Are you sure you want to permanently remove ${bed.id}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteBed(bed.id);
              if (mounted) {
                Navigator.pop(c); // dialog
                Navigator.pop(context); // sheet
              }
            }, 
            child: const Text('Delete', style: TextStyle(color: AppTheme.critical))
          ),
        ],
      )
    );
  }

  Widget _buildStatusButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(16),
            Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bedsAsync = ref.watch(realBedsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hospital Map'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Search specific bed ID (e.g., ICU-2)',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toUpperCase()),
                ),
              ),
              const Gap(16),
              bedsAsync.when(
                data: (beds) {
                  int icuFree = beds.where((b) => b.type == 'ICU' && b.status == 'Available').length;
                  int genFree = beds.where((b) => b.type == 'General' && b.status == 'Available').length;
                  int emrFree = beds.where((b) => b.type == 'Emergency' && b.status == 'Available').length;
                  int maint = beds.where((b) => b.status == 'Maintenance').length;
                  return Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryTick('ICU', icuFree),
                        _buildSummaryTick('GEN', genFree),
                        _buildSummaryTick('EMR', emrFree),
                        _buildSummaryTick('MAINT', maint, color: Colors.orange),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox(height: 40),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'ICU'),
                  Tab(text: 'General'),
                  Tab(text: 'Emergency'),
                ],
              ),
            ],
          )
        ),
      ),
      body: bedsAsync.when(
        data: (allBeds) {
          final filteredBeds = allBeds.where((b) => b.id.contains(_searchQuery)).toList();
          
          if (_searchQuery.isNotEmpty) {
             return _buildBedGrid(filteredBeds);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBedGrid(allBeds.where((b) => b.type == 'ICU').toList()),
              _buildBedGrid(allBeds.where((b) => b.type == 'General').toList()),
              _buildBedGrid(allBeds.where((b) => b.type == 'Emergency').toList()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryTick(String title, int count, {Color? color}) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color ?? (count > 0 ? AppTheme.stable : AppTheme.critical), shape: BoxShape.circle)),
        const Gap(6),
        Text('$title: $count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildBedGrid(List<BedModel> beds) {
    if (beds.isEmpty) {
      return const Center(child: Text('No matching beds found.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final bed = beds[index];
            return BedCard(
              bed: bed,
              onTap: () {
                final user = ref.read(authNotifierProvider);
                if (user?.role == 'Admin') {
                  _showStatusUpdateSheet(context, bed);
                } else if (bed.status == 'Occupied') {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bed ${bed.id}: Occupied by ${bed.patientName ?? "Active Patient"}')));
                } else if (bed.status == 'Maintenance') {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bed ${bed.id} is currently under maintenance.')));
                }
              },
            ).animate().fade().scaleXY(begin: 0.9, duration: 300.ms, delay: (index * 20).ms);
          },
        );
      }
    );
  }
}
