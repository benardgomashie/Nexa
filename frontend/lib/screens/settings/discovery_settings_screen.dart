import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';

class DiscoverySettingsScreen extends ConsumerStatefulWidget {
  const DiscoverySettingsScreen({super.key});

  @override
  ConsumerState<DiscoverySettingsScreen> createState() =>
      _DiscoverySettingsScreenState();
}

class _DiscoverySettingsScreenState
    extends ConsumerState<DiscoverySettingsScreen> {
  bool _isLoading = false;
  bool _isVisible = true;
  double _radiusKm = 10.0;
  Position? _currentPosition;

  // Available radius options (matching v1 spec)
  final List<double> _radiusOptions = [1, 3, 5, 10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _getCurrentLocation();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await ref.read(profileProvider.notifier).getPreferences();
      if (prefs != null && mounted) {
        setState(() {
          _isVisible = prefs['visible'] as bool? ?? true;
          _radiusKm = (prefs['radius_km'] as num?)?.toDouble() ?? 10.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _updateRadius(double radius) async {
    setState(() {
      _radiusKm = radius;
      _isLoading = true;
    });

    try {
      await ref.read(profileProvider.notifier).updateLocationPreference(
            radiusKm: radius.toInt(),
            latitude: _currentPosition?.latitude,
            longitude: _currentPosition?.longitude,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search radius updated to ${radius.toInt()}km'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update radius: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVisibility(bool visible) async {
    setState(() {
      _isVisible = visible;
      _isLoading = true;
    });

    try {
      await ref.read(profileProvider.notifier).updateVisibility(visible);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(visible
                ? 'Your profile is now visible in discovery'
                : 'Your profile is now hidden from discovery'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() => _isVisible = !visible);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update visibility: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Visibility toggle section
                _buildSectionHeader('Profile Visibility'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Show me in Discovery',
                                    style: AppTheme.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isVisible
                                        ? 'Others can find you nearby'
                                        : 'You\'re hidden from discovery',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isVisible,
                              onChanged: _updateVisibility,
                              activeColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                        if (!_isVisible) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppTheme.warning, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your profile won\'t appear in others\' discovery. You can still see and connect with people.',
                                    style: AppTheme.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Location radius section
                _buildSectionHeader('Search Radius'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How far to search for people',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Currently set to ${_radiusKm.toInt()}km',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _radiusOptions.map((radius) {
                            final isSelected = _radiusKm == radius;
                            return ChoiceChip(
                              label: Text('${radius.toInt()}km'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) _updateRadius(radius);
                              },
                              selectedColor:
                                  AppTheme.primaryColor.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getRadiusDescription(_radiusKm),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Location status
                _buildSectionHeader('Your Location'),
                Card(
                  child: ListTile(
                    leading: Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _currentPosition != null
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    title: Text(
                      _currentPosition != null
                          ? 'Location detected'
                          : 'Location not available',
                    ),
                    subtitle: Text(
                      _currentPosition != null
                          ? 'Using your current location for discovery'
                          : 'Enable location to find people nearby',
                    ),
                    trailing: _currentPosition == null
                        ? TextButton(
                            onPressed: _getCurrentLocation,
                            child: const Text('Enable'),
                          )
                        : null,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTheme.headline3.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  String _getRadiusDescription(double radius) {
    if (radius <= 1) {
      return 'Walking distance — people very close to you';
    } else if (radius <= 3) {
      return 'Short commute — your immediate neighborhood';
    } else if (radius <= 5) {
      return 'Local area — a short drive away';
    } else if (radius <= 10) {
      return 'Your district — moderate distance';
    } else if (radius <= 25) {
      return 'Your city — wider search area';
    } else {
      return 'Extended area — covers nearby towns';
    }
  }
}
