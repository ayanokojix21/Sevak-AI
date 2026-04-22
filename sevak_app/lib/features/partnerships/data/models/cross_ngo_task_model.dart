import '../../domain/entities/cross_ngo_task_entity.dart';

class CrossNgoTaskModel extends CrossNgoTaskEntity {
  CrossNgoTaskModel({
    required super.id,
    required super.needId,
    required super.sourceNgoId,
    required super.volunteerNgoId,
    super.volunteerUid,
    required super.volunteerConsentGiven,
    required super.status,
  });

  factory CrossNgoTaskModel.fromJson(Map<String, dynamic> json, String id) {
    return CrossNgoTaskModel(
      id: id,
      needId: json['needId'] as String? ?? '',
      sourceNgoId: json['sourceNgoId'] as String? ?? '',
      volunteerNgoId: json['volunteerNgoId'] as String? ?? '',
      volunteerUid: json['volunteerUid'] as String?,
      volunteerConsentGiven: json['volunteerConsentGiven'] as bool? ?? false,
      status: CrossNgoTaskStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'requested'),
        orElse: () => CrossNgoTaskStatus.requested,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'needId': needId,
      'sourceNgoId': sourceNgoId,
      'volunteerNgoId': volunteerNgoId,
      'volunteerUid': volunteerUid,
      'volunteerConsentGiven': volunteerConsentGiven,
      'status': status.name,
    };
  }
}
