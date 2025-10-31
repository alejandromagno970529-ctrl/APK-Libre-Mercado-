// lib/models/profile_model.dart
class Profile {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final double reputation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? verificationDocumentUrl;
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationReviewedAt;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.reputation,
    required this.createdAt,
    required this.updatedAt,
    required this.verificationStatus,
    this.verificationDocumentUrl,
    this.verificationSubmittedAt,
    this.verificationReviewedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      reputation: (json['reputation'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verificationDocumentUrl: json['verification_document_url'] as String?,
      verificationSubmittedAt: json['verification_submitted_at'] != null 
          ? DateTime.parse(json['verification_submitted_at'] as String)
          : null,
      verificationReviewedAt: json['verification_reviewed_at'] != null
          ? DateTime.parse(json['verification_reviewed_at'] as String)
          : null,
    );
  }

  bool get isVerified => verificationStatus == 'verified';
  bool get isVerificationPending => verificationStatus == 'pending';
  bool get isVerificationRejected => verificationStatus == 'rejected';
}