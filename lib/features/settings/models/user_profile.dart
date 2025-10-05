/// User profile configuration
class UserProfile {
  final String name;
  final String? photoPath;
  final String? bio;

  UserProfile({
    required this.name,
    this.photoPath,
    this.bio,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: '',
      photoPath: null,
      bio: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photoPath': photoPath,
      'bio': bio,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      bio: json['bio'] as String?,
    );
  }

  UserProfile copyWith({
    String? name,
    String? photoPath,
    String? bio,
  }) {
    return UserProfile(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      bio: bio ?? this.bio,
    );
  }
}
