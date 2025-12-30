import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _selectedPronouns;
  String? _selectedGender;
  bool _genderVisible = false;
  String? _selectedAgeBucket;
  String? _selectedFaith;
  final List<String> _selectedIntents = [];
  final List<String> _selectedInterests = [];

  final List<String> _ageBuckets = [
    '18_24',
    '25_34',
    '35_44',
    '45_54',
    '55_plus',
  ];

  final Map<String, String> _ageBucketDisplayNames = {
    '18_24': '18-24',
    '25_34': '25-34',
    '35_44': '35-44',
    '45_54': '45-54',
    '55_plus': '55+',
  };

  final List<String> _pronounOptions = [
    'he_him',
    'she_her',
    'they_them',
    'other',
    'prefer_not_to_say',
  ];

  final Map<String, String> _pronounDisplayNames = {
    'he_him': 'He/Him',
    'she_her': 'She/Her',
    'they_them': 'They/Them',
    'other': 'Other',
    'prefer_not_to_say': 'Prefer not to say',
  };

  final List<String> _genderOptions = [
    'male',
    'female',
    'non_binary',
    'other',
    'prefer_not_to_say',
  ];

  final Map<String, String> _genderDisplayNames = {
    'male': 'Male',
    'female': 'Female',
    'non_binary': 'Non-binary',
    'other': 'Other',
    'prefer_not_to_say': 'Prefer not to say',
  };

  final List<String> _faithOptions = [
    'christian',
    'muslim',
    'traditional',
    'other',
    'prefer_not_to_say',
  ];

  final Map<String, String> _faithDisplayNames = {
    'christian': 'Christian',
    'muslim': 'Muslim',
    'traditional': 'Traditional / Spiritual',
    'other': 'Other',
    'prefer_not_to_say': 'Prefer not to say',
  };

  final List<String> _intentOptions = [
    'Friendship',
    'Networking',
    'Dating',
    'Mentorship',
    'Activity Partner',
    'Language Exchange',
  ];

  final List<String> _interestOptions = [
    'Music',
    'Sports',
    'Art',
    'Technology',
    'Food',
    'Travel',
    'Reading',
    'Movies',
    'Gaming',
    'Fitness',
    'Photography',
    'Cooking',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = ref.read(authProvider).profile;
    if (profile != null) {
      _displayNameController.text = profile.displayName ?? '';
      _bioController.text = profile.bio ?? '';
      _selectedPronouns = (profile.pronouns?.isEmpty ?? true) ? null : profile.pronouns;
      _selectedGender = (profile.gender?.isEmpty ?? true) ? null : profile.gender;
      _genderVisible = profile.genderVisible;
      _selectedAgeBucket = (profile.ageBucket?.isEmpty ?? true) ? null : profile.ageBucket;
      _selectedFaith = (profile.faith?.isEmpty ?? true) ? null : profile.faith;
      _selectedIntents.addAll(profile.intentTags);
      _selectedInterests.addAll(profile.interestTags);
    }
  }

  @override
  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final success = await ref.read(profileProvider.notifier).uploadPhoto(
            File(pickedFile.path),
          );

      if (mounted) {
        if (success) {
          // Refresh auth profile
          await ref.read(authProvider.notifier).fetchCurrentUser();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          final error = ref.read(profileProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to upload photo'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(profileProvider.notifier).updateProfile(
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          pronouns: _selectedPronouns,
          gender: _selectedGender,
          genderVisible: _genderVisible,
          ageBucket: _selectedAgeBucket,
          faith: _selectedFaith,
          intentTags: _selectedIntents,
          interestTags: _selectedInterests,
        );

    if (mounted) {
      if (success) {
        // Refresh auth profile
        await ref.read(authProvider.notifier).fetchCurrentUser();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        
        context.pop();
      } else {
        final error = ref.read(profileProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update profile'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: profileState.isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photos section
                    Text(
                      'Photos',
                      style: AppTheme.headline2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add photo button
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 32,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Photo',
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Existing photos
                          if (profile?.photos != null)
                            ...profile!.photos.map((photo) => Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(photo.image),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final success = await ref
                                                .read(profileProvider.notifier)
                                                .deletePhoto(photo.id);
                                            if (success && mounted) {
                                              await ref
                                                  .read(authProvider.notifier)
                                                  .fetchCurrentUser();
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display name
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name *',
                        hintText: 'How should people call you?',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Bio *',
                        hintText: 'Tell people about yourself...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a bio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pronouns
                    DropdownButtonFormField<String>(
                      value: _selectedPronouns,
                      decoration: const InputDecoration(
                        labelText: 'Pronouns (Optional)',
                      ),
                      items: _pronounOptions
                          .map((pronoun) => DropdownMenuItem(
                                value: pronoun,
                                child: Text(_pronounDisplayNames[pronoun]!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPronouns = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender with visibility toggle
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender (Optional)',
                      ),
                      items: _genderOptions
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(_genderDisplayNames[gender]!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    if (_selectedGender != null && _selectedGender != 'prefer_not_to_say')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _genderVisible,
                              onChanged: (value) {
                                setState(() {
                                  _genderVisible = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Show gender on my profile',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Age bucket
                    DropdownButtonFormField<String>(
                      value: _selectedAgeBucket,
                      decoration: const InputDecoration(
                        labelText: 'Age Range *',
                      ),
                      items: _ageBuckets
                          .map((bucket) => DropdownMenuItem(
                                value: bucket,
                                child: Text(_ageBucketDisplayNames[bucket]!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAgeBucket = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an age range';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Faith
                    DropdownButtonFormField<String>(
                      value: _selectedFaith,
                      decoration: const InputDecoration(
                        labelText: 'Faith (Optional)',
                      ),
                      items: _faithOptions
                          .map((faith) => DropdownMenuItem(
                                value: faith,
                                child: Text(_faithDisplayNames[faith]!),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFaith = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Intent tags
                    Text(
                      'What are you looking for? *',
                      style: AppTheme.headline3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _intentOptions.map((intent) {
                        final isSelected = _selectedIntents.contains(intent);
                        return FilterChip(
                          label: Text(
                            intent,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedIntents.add(intent);
                              } else {
                                _selectedIntents.remove(intent);
                              }
                            });
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Interest tags
                    Text(
                      'Your Interests',
                      style: AppTheme.headline3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _interestOptions.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected ? AppTheme.accentColor : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                          selectedColor: AppTheme.accentColor.withOpacity(0.3),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: profileState.isLoading ? null : _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
