/// Profile model matching backend schema
class Profile {
  final int id;
  final int userId;
  final String? displayName;
  final String? bio;
  final String? pronouns;
  final String? gender;
  final bool genderVisible;
  final String? ageBucket;
  final String primaryLanguage;
  final List<String> otherLanguages;
  final String? faith;
  final bool faithVisible;
  final String? hometown;
  final double? latitude;
  final double? longitude;
  final bool isVisible;
  final List<ProfilePhoto> photos;
  final List<String> intentTags;
  final List<String> interestTags;

  Profile({
    required this.id,
    required this.userId,
    this.displayName,
    this.bio,
    this.pronouns,
    this.gender,
    this.genderVisible = false,
    this.ageBucket,
    this.primaryLanguage = 'English',
    this.otherLanguages = const [],
    this.faith,
    this.faithVisible = false,
    this.hometown,
    this.latitude,
    this.longitude,
    this.isVisible = true,
    this.photos = const [],
    this.intentTags = const [],
    this.interestTags = const [],
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    print('[PROFILE_MODEL] Parsing profile from JSON...');
    print('[PROFILE_MODEL] Raw photos data: ${json['photos']}');
    
    final photosList = json['photos'] as List<dynamic>?;
    print('[PROFILE_MODEL] Photos list type: ${photosList?.runtimeType}');
    print('[PROFILE_MODEL] Photos list length: ${photosList?.length}');
    
    final parsedPhotos = photosList
            ?.map((e) {
              print('[PROFILE_MODEL] Parsing photo: $e');
              return ProfilePhoto.fromJson(e as Map<String, dynamic>);
            })
            .toList() ??
        [];
    print('[PROFILE_MODEL] Parsed photos count: ${parsedPhotos.length}');
    
    return Profile(
      id: json['id'] as int,
      userId: (json['user'] as int?) ?? (json['id'] as int), // Fallback to id if user field not present
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      pronouns: json['pronouns'] as String?,
      gender: json['gender'] as String?,
      genderVisible: json['gender_visible'] as bool? ?? false,
      ageBucket: json['age_bucket'] as String?,
      primaryLanguage: json['primary_language'] as String? ?? 'English',
      otherLanguages: (json['other_languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      faith: json['faith'] as String?,
      faithVisible: json['faith_visible'] as bool? ?? false,
      hometown: json['hometown'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isVisible: json['is_visible'] as bool? ?? true,
      photos: parsedPhotos,
      intentTags: (json['intents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interestTags: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'display_name': displayName,
      'bio': bio,
      'pronouns': pronouns,
      'gender': gender,
      'gender_visible': genderVisible,
      'age_bucket': ageBucket,
      'primary_language': primaryLanguage,
      'other_languages': otherLanguages,
      'faith': faith,
      'faith_visible': faithVisible,
      'hometown': hometown,
      'latitude': latitude,
      'longitude': longitude,
      'is_visible': isVisible,
      'intent_tags': intentTags,
      'interest_tags': interestTags,
    };
  }

  bool get isComplete {
    return displayName != null &&
        bio != null &&
        ageBucket != null &&
        latitude != null &&
        longitude != null &&
        photos.isNotEmpty &&
        intentTags.isNotEmpty;
  }

  Profile copyWith({
    int? id,
    int? userId,
    String? displayName,
    String? bio,
    String? pronouns,
    String? gender,
    bool? genderVisible,
    String? ageBucket,
    String? primaryLanguage,
    List<String>? otherLanguages,
    String? faith,
    bool? faithVisible,
    String? hometown,
    double? latitude,
    double? longitude,
    bool? isVisible,
    List<ProfilePhoto>? photos,
    List<String>? intentTags,
    List<String>? interestTags,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      pronouns: pronouns ?? this.pronouns,
      gender: gender ?? this.gender,
      genderVisible: genderVisible ?? this.genderVisible,
      ageBucket: ageBucket ?? this.ageBucket,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      otherLanguages: otherLanguages ?? this.otherLanguages,
      faith: faith ?? this.faith,
      faithVisible: faithVisible ?? this.faithVisible,
      hometown: hometown ?? this.hometown,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVisible: isVisible ?? this.isVisible,
      photos: photos ?? this.photos,
      intentTags: intentTags ?? this.intentTags,
      interestTags: interestTags ?? this.interestTags,
    );
  }
}

class ProfilePhoto {
  final int id;
  final String image;
  final int order;

  ProfilePhoto({
    required this.id,
    required this.image,
    required this.order,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: json['id'] as int,
      image: json['image'] as String,
      order: json['ordering_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'order': order,
    };
  }
}
