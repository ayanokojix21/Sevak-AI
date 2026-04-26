import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../needs/domain/entities/need_entity.dart';
import '../../domain/entities/community_report_entity.dart';

class CommunityReportModel extends CommunityReportEntity {
  const CommunityReportModel({
    required super.id,
    required super.rawText,
    super.imageUrl,
    required super.location,
    required super.lat,
    required super.lng,
    required super.needType,
    required super.urgencyScore,
    required super.urgencyReason,
    required super.peopleAffected,
    required super.status,
    required super.submittedBy,
    required super.targetNgoId,
    required super.createdAt,
    super.scaleAssessment,
  });

  factory CommunityReportModel.fromEntity(CommunityReportEntity entity) {
    return CommunityReportModel(
      id: entity.id,
      rawText: entity.rawText,
      imageUrl: entity.imageUrl,
      location: entity.location,
      lat: entity.lat,
      lng: entity.lng,
      needType: entity.needType,
      urgencyScore: entity.urgencyScore,
      urgencyReason: entity.urgencyReason,
      peopleAffected: entity.peopleAffected,
      status: entity.status,
      submittedBy: entity.submittedBy,
      targetNgoId: entity.targetNgoId,
      createdAt: entity.createdAt,
      scaleAssessment: entity.scaleAssessment,
    );
  }

  factory CommunityReportModel.fromJson(Map<String, dynamic> json, String id) {
    return CommunityReportModel(
      id: id,
      rawText: json['rawText'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String? ?? 'Unknown',
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? 0) as num).toDouble(),
      needType: json['needType'] as String? ?? 'OTHER',
      urgencyScore: (json['urgencyScore'] as num?)?.toInt() ?? 0,
      urgencyReason: json['urgencyReason'] as String? ?? '',
      peopleAffected: (json['peopleAffected'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'PENDING_APPROVAL',
      submittedBy: json['submittedBy'] as String? ?? '',
      targetNgoId: json['targetNgoId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scaleAssessment: json['scaleAssessment'] != null 
          ? ScaleAssessment.fromJson(json['scaleAssessment'] as Map<String, dynamic>) 
          : ScaleAssessment.empty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'imageUrl': imageUrl,
      'location': location,
      'lat': lat,
      'lng': lng,
      'needType': needType,
      'urgencyScore': urgencyScore,
      'urgencyReason': urgencyReason,
      'peopleAffected': peopleAffected,
      'status': status,
      'submittedBy': submittedBy,
      'targetNgoId': targetNgoId,
      'createdAt': FieldValue.serverTimestamp(),
      'scaleAssessment': scaleAssessment.toJson(),
    };
  }
}
