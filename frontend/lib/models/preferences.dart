/// MatchingPreference model matching backend schema
class MatchingPreference {
  final int id;
  final List<String> intents;
  final List<String> interests;
  final List<String> ageBuckets;
  final Map<String, bool> availability;
  final String faithFilter;

  MatchingPreference({
    required this.id,
    this.intents = const [],
    this.interests = const [],
    this.ageBuckets = const [],
    Map<String, bool>? availability,
    this.faithFilter = 'open_to_all',
  }) : availability = availability ??
            {
              'morning': false,
              'afternoon': false,
              'evening': false,
              'weekday': false,
              'weekend': false,
            };

  factory MatchingPreference.fromJson(Map<String, dynamic> json) {
    return MatchingPreference(
      id: json['id'] as int,
      intents: (json['intents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ageBuckets: (json['age_buckets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availability: (json['availability'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as bool)) ??
          {},
      faithFilter: json['faith_filter'] as String? ?? 'open_to_all',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intents': intents,
      'interests': interests,
      'age_buckets': ageBuckets,
      'availability': availability,
      'faith_filter': faithFilter,
    };
  }
}

/// LocationPreference model matching backend schema
class LocationPreference {
  final int id;
  final double? latitude;
  final double? longitude;
  final String? city;
  final double radiusKm;

  LocationPreference({
    required this.id,
    this.latitude,
    this.longitude,
    this.city,
    this.radiusKm = 25.0,
  });

  factory LocationPreference.fromJson(Map<String, dynamic> json) {
    return LocationPreference(
      id: json['id'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 25.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'radius_km': radiusKm,
    };
  }
}
