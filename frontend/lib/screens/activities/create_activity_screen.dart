import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../providers/service_providers.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _capacityController = TextEditingController(text: '10');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int? _durationMinutes = 60;
  int? _selectedCategoryId;
  ActivityVisibility _visibility = ActivityVisibility.public;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location to be detected')),
      );
      return;
    }

    final locationName = _locationNameController.text.trim();
    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateActivityRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        date: _selectedDate,
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        durationMinutes: _durationMinutes,
        latitude: _latitude!,
        longitude: _longitude!,
        locationName: locationName,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 10,
        visibility: _visibility,
      );

      final activityService = ref.read(activityServiceProvider);
      final activity = await activityService.createActivity(request);

      // Refresh activities list
      ref.read(activitiesProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity created successfully!')),
        );
        context.go('/activities/${activity.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating activity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(activityCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Activity'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Coffee & Chat at Starbucks',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell people what to expect...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}'),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Failed to load categories'),
            ),
            const SizedBox(height: 24),

            // Date & Time section
            const Text(
              'When',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Date picker
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Time picker
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duration
            DropdownButtonFormField<int?>(
              value: _durationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timelapse),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
                DropdownMenuItem(value: 180, child: Text('3 hours')),
                DropdownMenuItem(value: null, child: Text('Flexible')),
              ],
              onChanged: (value) {
                setState(() => _durationMinutes = value);
              },
            ),
            const SizedBox(height: 24),

            // Location section
            const Text(
              'Where',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Location name
            TextFormField(
              controller: _locationNameController,
              decoration: const InputDecoration(
                labelText: 'Location name',
                hintText: 'e.g., Central Park',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                hintText: 'e.g., 123 Main St',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),

            // Current location indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _latitude != null
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _latitude != null ? Icons.check_circle : Icons.info_outline,
                    color: _latitude != null ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingLocation
                          ? 'Getting your location...'
                          : _latitude != null
                              ? 'Using your current location'
                              : 'Location required to create activity',
                      style: TextStyle(
                        color: _latitude != null ? Colors.green : Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!_isLoadingLocation && _latitude == null)
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Capacity & Visibility section
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Capacity
                Expanded(
                  child: TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Max participants',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final capacity = int.tryParse(value ?? '');
                      if (capacity == null || capacity < 2) {
                        return 'Min 2 people';
                      }
                      if (capacity > 100) {
                        return 'Max 100 people';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Visibility
                Expanded(
                  child: DropdownButtonFormField<ActivityVisibility>(
                    value: _visibility,
                    decoration: const InputDecoration(
                      labelText: 'Visibility',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.visibility),
                    ),
                    items: ActivityVisibility.values
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v == ActivityVisibility.public
                                    ? 'Public'
                                    : v == ActivityVisibility.connections
                                        ? 'Connections'
                                        : 'Invite Only',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || _latitude == null
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
