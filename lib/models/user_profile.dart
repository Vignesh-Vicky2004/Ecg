import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/utils.dart';

/// User profile model for storing user information
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final Map<String, dynamic>? medicalInfo;
  
  // Additional properties referenced in the app
  final String? name;
  final String? phone;
  final int? age;
  final double? height;
  final double? weight;
  final String? activityLevel;
  final String? bloodType;
  final bool? hasHeartConditions;
  final List<String>? medicalConditions;
  final String? emergencyContact;
  final String? emergencyPhone;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isEmailVerified,
    this.medicalInfo,
    this.name,
    this.phone,
    this.age,
    this.height,
    this.weight,
    this.activityLevel,
    this.bloodType,
    this.hasHeartConditions,
    this.medicalConditions,
    this.emergencyContact,
    this.emergencyPhone,
  });

  /// Create UserProfile from Firebase User
  factory UserProfile.fromFirebaseUser(User user) {
    final now = DateTime.now();
    return UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      profileImageUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: now,
      isEmailVerified: user.emailVerified,
    );
  }

  /// Create UserProfile from map (Firestore document)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      dateOfBirth: _parseDateTime(map['dateOfBirth']),
      gender: map['gender'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      isEmailVerified: map['isEmailVerified'] ?? false,
      medicalInfo: map['medicalInfo']?.cast<String, dynamic>(),
      name: map['name'],
      phone: map['phone'],
      age: map['age']?.toInt(),
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      activityLevel: map['activityLevel'],
      bloodType: map['bloodType'],
      hasHeartConditions: map['hasHeartConditions'],
      medicalConditions: _parseMedicalConditions(map['medicalConditions']),
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
    );
  }

  /// Helper method to safely parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    try {
      // If it's already an int (milliseconds since epoch)
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      
      // If it's a string, try to parse it
      if (value is String) {
        return DateTime.parse(value);
      }
      
      // If it's a Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return value.toDate();
      }
      
      return null;
    } catch (e) {
      LoggerService.error('Error parsing DateTime: $e');
      return null;
    }
  }

  /// Helper method to safely parse medical conditions from various formats
  static List<String>? _parseMedicalConditions(dynamic value) {
    if (value == null) return null;
    
    try {
      // If it's already a List
      if (value is List) {
        return value.cast<String>();
      }
      
      // If it's an empty string, return empty list
      if (value is String && value.trim().isEmpty) {
        return <String>[];
      }
      
      // If it's a non-empty string, split by comma
      if (value is String) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      
      return null;
    } catch (e) {
      LoggerService.error('Error parsing medical conditions: $e');
      return <String>[];
    }
  }

  /// Convert UserProfile to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isEmailVerified': isEmailVerified,
      'medicalInfo': medicalInfo,
      'name': name,
      'phone': phone,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'bloodType': bloodType,
      'hasHeartConditions': hasHeartConditions,
      'medicalConditions': medicalConditions,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
    };
  }

  /// Copy with method for immutable updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    Map<String, dynamic>? medicalInfo,
    String? name,
    String? phone,
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? bloodType,
    bool? hasHeartConditions,
    List<String>? medicalConditions,
    String? emergencyContact,
    String? emergencyPhone,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      bloodType: bloodType ?? this.bloodType,
      hasHeartConditions: hasHeartConditions ?? this.hasHeartConditions,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName ?? email.split('@').first;
  }

  /// Get initials for avatar
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0].toUpperCase()}${lastName![0].toUpperCase()}';
    }
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return firstName != null &&
           lastName != null &&
           dateOfBirth != null &&
           gender != null;
  }

  /// Get age from date of birth if age field is null
  int? get calculatedAge {
    if (age != null) return age;
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// Helper getters for backward compatibility
  String? get ageString => age?.toString() ?? calculatedAge?.toString();
  String? get heightString => height?.toString();
  String? get weightString => weight?.toString();

  @override
  String toString() {
    return 'UserProfile(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
           other.uid == uid &&
           other.email == email &&
           other.displayName == displayName &&
           other.firstName == firstName &&
           other.lastName == lastName;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
           email.hashCode ^
           displayName.hashCode ^
           firstName.hashCode ^
           lastName.hashCode;
  }
}