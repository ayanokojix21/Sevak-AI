import 'package:equatable/equatable.dart';

/// Represents a volunteer's request to join an NGO.
/// Status flow: pending → approved/rejected
class JoinRequest extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String ngoId;
  final String ngoName;
  final String status; // 'pending', 'approved', 'rejected'
  final String message; // volunteer's intro message
  final String? rejectionReason;
  final DateTime createdAt;

  const JoinRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.ngoId,
    required this.ngoName,
    required this.status,
    this.message = '',
    this.rejectionReason,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json, String id) {
    return JoinRequest(
      id: id,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      ngoId: json['ngoId'] as String? ?? '',
      ngoName: json['ngoName'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String? ?? '',
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'ngoId': ngoId,
        'ngoName': ngoName,
        'status': status,
        'message': message,
        'rejectionReason': rejectionReason,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, userId, userName, userEmail, ngoId,
        ngoName, status, message, rejectionReason, createdAt,
      ];
}
