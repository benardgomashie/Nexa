/// Activity models matching backend schema

// Activity Category
class ActivityCategory {
  final int id;
  final String name;
  final String icon;
  final String description;
  final bool isActive;

  ActivityCategory({
    required this.id,
    required this.name,
    this.icon = '',
    this.description = '',
    this.isActive = true,
  });

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'is_active': isActive,
    };
  }
}

// Activity Status enum
enum ActivityStatus {
  draft,
  open,
  full,
  cancelled,
  completed;

  static ActivityStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return ActivityStatus.draft;
      case 'open':
        return ActivityStatus.open;
      case 'full':
        return ActivityStatus.full;
      case 'cancelled':
        return ActivityStatus.cancelled;
      case 'completed':
        return ActivityStatus.completed;
      default:
        return ActivityStatus.open;
    }
  }

  String toJson() => name;
}

// Activity Visibility enum
enum ActivityVisibility {
  public,
  connections,
  invite;

  static ActivityVisibility fromString(String value) {
    switch (value.toLowerCase()) {
      case 'public':
        return ActivityVisibility.public;
      case 'connections':
        return ActivityVisibility.connections;
      case 'invite':
        return ActivityVisibility.invite;
      default:
        return ActivityVisibility.public;
    }
  }

  String toJson() => name;

  String get displayName {
    switch (this) {
      case ActivityVisibility.public:
        return 'Public (Anyone nearby)';
      case ActivityVisibility.connections:
        return 'Connections Only';
      case ActivityVisibility.invite:
        return 'Invite Only';
    }
  }
}

// Participant Status enum
enum ParticipantStatus {
  pending,
  confirmed,
  declined,
  cancelled,
  removed;

  static ParticipantStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ParticipantStatus.pending;
      case 'confirmed':
        return ParticipantStatus.confirmed;
      case 'declined':
        return ParticipantStatus.declined;
      case 'cancelled':
        return ParticipantStatus.cancelled;
      case 'removed':
        return ParticipantStatus.removed;
      default:
        return ParticipantStatus.pending;
    }
  }

  String toJson() => name;
}

// Activity Host (simplified user)
class ActivityHost {
  final int id;
  final String displayName;
  final String? profilePhotoUrl;

  ActivityHost({
    required this.id,
    required this.displayName,
    this.profilePhotoUrl,
  });

  factory ActivityHost.fromJson(Map<String, dynamic> json) {
    return ActivityHost(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }
}

// Activity Participant
class ActivityParticipant {
  final int id;
  final int userId;
  final String displayName;
  final String? profilePhotoUrl;
  final ParticipantStatus status;
  final DateTime requestedAt;
  final String? message;

  ActivityParticipant({
    required this.id,
    required this.userId,
    required this.displayName,
    this.profilePhotoUrl,
    required this.status,
    required this.requestedAt,
    this.message,
  });

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) {
    // Parse user profile if available
    String displayName = 'Unknown';
    String? photoUrl;
    int userId = json['user'] as int? ?? 0;

    if (json['user_profile'] != null) {
      final profile = json['user_profile'] as Map<String, dynamic>;
      displayName = profile['display_name'] as String? ?? 'Unknown';
      if (profile['photos'] != null && (profile['photos'] as List).isNotEmpty) {
        photoUrl = (profile['photos'] as List).first['image'] as String?;
      }
    }

    return ActivityParticipant(
      id: json['id'] as int,
      userId: userId,
      displayName: displayName,
      profilePhotoUrl: photoUrl,
      status: ParticipantStatus.fromString(json['status'] as String),
      requestedAt: DateTime.parse(json['requested_at'] as String),
      message: json['message'] as String?,
    );
  }
}

// Location for Activity
class ActivityLocation {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  ActivityLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  factory ActivityLocation.fromJson(Map<String, dynamic> json) {
    return ActivityLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['location_name'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'location_name': name,
      'address': address,
    };
  }
}

// Main Activity model for list view
class Activity {
  final int id;
  final ActivityHost host;
  final String title;
  final String? description;
  final ActivityCategory? category;
  final DateTime date;
  final String? time;
  final int? durationMinutes;
  final ActivityLocation location;
  final int capacity;
  final int confirmedCount;
  final ActivityStatus status;
  final ActivityVisibility visibility;
  final double? distance;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.host,
    required this.title,
    this.description,
    this.category,
    required this.date,
    this.time,
    this.durationMinutes,
    required this.location,
    required this.capacity,
    required this.confirmedCount,
    required this.status,
    required this.visibility,
    this.distance,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Parse host from either 'host' object or 'host_profile' object
    ActivityHost host;
    if (json['host'] != null) {
      host = ActivityHost.fromJson(json['host'] as Map<String, dynamic>);
    } else if (json['host_profile'] != null) {
      final hp = json['host_profile'] as Map<String, dynamic>;
      host = ActivityHost(
        id: hp['user_id'] as int,
        displayName: hp['display_name'] as String? ?? 'Unknown',
        profilePhotoUrl: hp['photo'] as String?,
      );
    } else {
      host = ActivityHost(id: 0, displayName: 'Unknown');
    }

    // Parse category
    ActivityCategory? category;
    if (json['category_data'] != null) {
      category = ActivityCategory.fromJson(json['category_data'] as Map<String, dynamic>);
    } else if (json['category'] != null && json['category'] is Map) {
      category = ActivityCategory.fromJson(json['category'] as Map<String, dynamic>);
    }

    // Parse location
    ActivityLocation location;
    try {
      location = ActivityLocation(
        latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : 0.0,
        longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : 0.0,
        name: json['location_name'] as String?,
        address: json['location_address'] as String?,
      );
    } catch (e) {
      location = ActivityLocation(latitude: 0, longitude: 0);
    }

    return Activity(
      id: json['id'] as int,
      host: host,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: category,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      location: location,
      capacity: json['max_participants'] as int? ?? 10,
      confirmedCount: json['participant_count'] as int? ?? 0,
      status: ActivityStatus.fromString(json['status'] as String),
      visibility: ActivityVisibility.fromString(json['visibility'] as String),
      distance: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Get combined DateTime for display
  DateTime get dateTime {
    if (time != null && time!.isNotEmpty) {
      try {
        final parts = time!.split(':');
        return DateTime(date.year, date.month, date.day,
            int.parse(parts[0]), int.parse(parts[1]));
      } catch (e) {
        return date;
      }
    }
    return date;
  }

  int get spotsLeft => capacity - confirmedCount;
  bool get isFull => spotsLeft <= 0;
  bool get isUpcoming => date.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  bool get isPast => date.isBefore(DateTime.now());
}

// Detailed Activity model with participants
class ActivityDetail extends Activity {
  final List<ActivityParticipant> participants;
  final String? allowedGender;
  final String? minAge;
  final String? maxAge;
  final List<String>? allowedIntents;
  final bool isHost;
  final ParticipantStatus? myStatus;

  ActivityDetail({
    required super.id,
    required super.host,
    required super.title,
    super.description,
    super.category,
    required super.date,
    super.time,
    super.durationMinutes,
    required super.location,
    required super.capacity,
    required super.confirmedCount,
    required super.status,
    required super.visibility,
    super.distance,
    required super.createdAt,
    required this.participants,
    this.allowedGender,
    this.minAge,
    this.maxAge,
    this.allowedIntents,
    this.isHost = false,
    this.myStatus,
  });

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    // Parse host from either 'host' object or 'host_profile' object
    ActivityHost host;
    if (json['host_profile'] != null) {
      final hp = json['host_profile'] as Map<String, dynamic>;
      host = ActivityHost(
        id: hp['user_id'] ?? hp['id'] ?? 0,
        displayName: hp['display_name'] as String? ?? 'Unknown',
        profilePhotoUrl: hp['photo'] as String?,
      );
    } else if (json['host'] != null) {
      host = ActivityHost.fromJson(json['host'] as Map<String, dynamic>);
    } else {
      host = ActivityHost(id: 0, displayName: 'Unknown');
    }

    // Parse category
    ActivityCategory? category;
    if (json['category_data'] != null) {
      category = ActivityCategory.fromJson(json['category_data'] as Map<String, dynamic>);
    } else if (json['category'] != null && json['category'] is Map) {
      category = ActivityCategory.fromJson(json['category'] as Map<String, dynamic>);
    }

    // Parse location
    ActivityLocation location;
    try {
      location = ActivityLocation(
        latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : 0.0,
        longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : 0.0,
        name: json['location_name'] as String?,
        address: json['location_address'] as String?,
      );
    } catch (e) {
      location = ActivityLocation(latitude: 0, longitude: 0);
    }

    // Parse participants
    List<ActivityParticipant> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List<dynamic>)
          .map((e) => ActivityParticipant.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ActivityDetail(
      id: json['id'] as int,
      host: host,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: category,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      location: location,
      capacity: json['max_participants'] as int? ?? 10,
      confirmedCount: json['participant_count'] as int? ?? 0,
      status: ActivityStatus.fromString(json['status'] as String),
      visibility: ActivityVisibility.fromString(json['visibility'] as String),
      distance: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      participants: participants,
      allowedGender: json['gender_filter']?.toString(),
      minAge: null,
      maxAge: null,
      allowedIntents: null,
      isHost: json['is_host'] as bool? ?? false,
      myStatus: json['user_status'] != null
          ? ParticipantStatus.fromString(json['user_status'] as String)
          : null,
    );
  }

  List<ActivityParticipant> get confirmedParticipants =>
      participants.where((p) => p.status == ParticipantStatus.confirmed).toList();

  List<ActivityParticipant> get pendingParticipants =>
      participants.where((p) => p.status == ParticipantStatus.pending).toList();
}

// Activity Message for chat
class ActivityMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  ActivityMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory ActivityMessage.fromJson(Map<String, dynamic> json) {
    return ActivityMessage(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      senderPhotoUrl: json['sender_photo_url'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

// Create Activity Request
class CreateActivityRequest {
  final String title;
  final String? description;
  final int? categoryId;
  final DateTime date;
  final String? time;
  final int? durationMinutes;
  final double latitude;
  final double longitude;
  final String locationName;
  final String? address;
  final int capacity;
  final ActivityVisibility visibility;

  CreateActivityRequest({
    required this.title,
    this.description,
    this.categoryId,
    required this.date,
    this.time,
    this.durationMinutes,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.address,
    this.capacity = 4,
    this.visibility = ActivityVisibility.public,
  });

  Map<String, dynamic> toJson() {
    // Format date as YYYY-MM-DD
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return {
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (categoryId != null) 'category': categoryId,
      'date': dateStr,
      if (time != null) 'time': time,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      if (address != null && address!.isNotEmpty) 'location_address': address,
      'max_participants': capacity,
      'visibility': visibility.toJson(),
    };
  }
}
