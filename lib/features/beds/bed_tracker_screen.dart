import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../app/theme.dart';
import '../../mock/mock_data.dart';
import '../../models/bed_model.dart';
import '../../core/dsa/bed_search.dart';
import 'widgets/bed_card.dart';

class BedTrackerScreen extends ConsumerStatefulWidget {
  const BedTrackerScreen({super.key});

  @override
  ConsumerState<BedTrackerScreen> createState() => _BedTrackerScreenState();
}

class _BedTrackerScreenState extends ConsumerState<BedTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  BedModel? _searchedBed;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showStatusUpdateSheet(BuildContext context, BedModel bed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Update Bed Status: ${bed.id}', style: Theme.of(context).textTheme.headlineMedium),
                    const Gap(8),
                    const Text('Selecting a new status applies changes instantly across the hospital command network.', style: TextStyle(color: AppTheme.textSecondary)),
                    const Gap(32),
                    
                    _buildStatusButton('Available', AppTheme.stable, Icons.check_circle_outline, () {
                      ref.read(bedsProvider.notifier).updateBedStatus(bed.id, 'Available');
                      Navigator.pop(context);
                    }),
                    const Gap(12),
                    _buildStatusButton('Occupied', AppTheme.critical, Icons.do_not_disturb_on, () {
                      ref.read(bedsProvider.notifier).updateBedStatus(bed.id, 'Occupied');
                      Navigator.pop(context);
                    }),
                    const Gap(12),
                    _buildStatusButton('Reserved', AppTheme.urgent, Icons.warning_amber_rounded, () {
                      ref.read(bedsProvider.notifier).updateBedStatus(bed.id, 'Reserved');
                      Navigator.pop(context);
                    }),
                    const Gap(24),
                  ],
                ),
              ),
            );
          }
        );
      },
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

  void _performSearch(String query, List<BedModel> allBeds) {
    if (query.isEmpty) {
      setState(() => _searchedBed = null);
      return;
    }
    // Deep DSA Hookup: Binary Search over sorted beds array
    // Our bed items were pre-sorted inside the provider.
    BedModel? found = BedSearch.binarySearch(allBeds, query.toUpperCase());
    setState(() => _searchedBed = found);
  }

  @override
  Widget build(BuildContext context) {
    final allBeds = ref.watch(bedsProvider);

    int icuFree = allBeds.where((b) => b.type == 'ICU' && b.status == 'Available').length;
    int genFree = allBeds.where((b) => b.type == 'General' && b.status == 'Available').length;
    int emrFree = allBeds.where((b) => b.type == 'Emergency' && b.status == 'Available').length;

    return Scaffold(
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
                  ),
                  onChanged: (val) => _performSearch(val, allBeds),
                ),
              ),
              const Gap(16),
              Container(
                color: AppTheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryTick('ICU', icuFree),
                    _buildSummaryTick('GEN', genFree),
                    _buildSummaryTick('EMR', emrFree),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryDark,
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
      body: _searchedBed != null 
        ? Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Gap(16),
                BedCard(bed: _searchedBed!, onTap: () => _showStatusUpdateSheet(context, _searchedBed!)),
              ],
            ),
          )
        : TabBarView(
          controller: _tabController,
          children: [
            _buildBedGrid(allBeds.where((b) => b.type == 'ICU').toList()),
            _buildBedGrid(allBeds.where((b) => b.type == 'General').toList()),
            _buildBedGrid(allBeds.where((b) => b.type == 'Emergency').toList()),
          ],
        ),
    );
  }

  Widget _buildSummaryTick(String title, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: count > 0 ? AppTheme.stable : AppTheme.critical, shape: BoxShape.circle)),
        const Gap(6),
        Text('$title: $count free', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildBedGrid(List<BedModel> beds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: beds.length,
          itemBuilder: (context, index) {
            final bed = beds[index];
            return BedCard(
              bed: bed,
              onTap: () => _showStatusUpdateSheet(context, bed),
            ).animate().fade().scaleXY(begin: 0.9, duration: 300.ms, delay: (index * 20).ms);
          },
        );
      }
    );
  }
}
