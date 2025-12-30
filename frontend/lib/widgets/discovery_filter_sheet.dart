import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/discovery_provider.dart';

/// Available intent options
const List<String> _intentOptions = [
  'Friendship',
  'Dating',
  'Networking',
  'Activity Partner',
];

/// Discovery filter bottom sheet
class DiscoveryFilterSheet extends ConsumerStatefulWidget {
  final DiscoveryFilters currentFilters;
  final Function(DiscoveryFilters) onApply;

  const DiscoveryFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onApply,
  });

  @override
  ConsumerState<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends ConsumerState<DiscoveryFilterSheet> {
  late int _selectedRadius;
  late String? _selectedIntent;
  late String? _selectedFaith;

  final List<int> _radiusOptions = [1, 3, 5, 10, 25, 50];

  @override
  void initState() {
    super.initState();
    _selectedRadius = widget.currentFilters.radiusKm ?? 25;
    _selectedIntent = widget.currentFilters.intent;
    _selectedFaith = widget.currentFilters.faith;
  }

  void _applyFilters() {
    final filters = DiscoveryFilters(
      radiusKm: _selectedRadius,
      intent: _selectedIntent,
      faith: _selectedFaith == 'same' ? 'same' : null,
    );
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedRadius = 25;
      _selectedIntent = null;
      _selectedFaith = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Profiles', style: AppTheme.headline2),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Distance filter
          Text('Distance', style: AppTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _radiusOptions.map((radius) {
              final isSelected = _selectedRadius == radius;
              return ChoiceChip(
                label: Text('${radius}km'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedRadius = radius);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Intent filter
          Text('Looking for', style: AppTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedIntent == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedIntent = null);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              ),
              ..._intentOptions.map((intent) {
                final isSelected = _selectedIntent == intent;
                return FilterChip(
                  label: Text(intent),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedIntent = selected ? intent : null;
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Faith filter
          Text('Faith', style: AppTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedFaith != 'same',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFaith = null);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              ),
              ChoiceChip(
                label: const Text('Same as mine'),
                selected: _selectedFaith == 'same',
                onSelected: (selected) {
                  setState(() => _selectedFaith = selected ? 'same' : null);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Show the filter bottom sheet
Future<void> showDiscoveryFilterSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final currentFilters = ref.read(discoveryProvider).filters;
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DiscoveryFilterSheet(
      currentFilters: currentFilters,
      onApply: (filters) {
        ref.read(discoveryProvider.notifier).applyFilters(filters);
      },
    ),
  );
}
