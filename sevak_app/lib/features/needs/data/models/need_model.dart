import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/need_entity.dart';

class NeedModel extends NeedEntity {
  const NeedModel({
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
    super.submittedByName = 'Unknown',
    super.assignedTo,
    super.assignedVolunteerIds = const [],
    super.rejectedBy = const [],
    super.matchReason,
    required super.ngoId,
    required super.createdAt,
    super.updatedAt,
    super.scaleAssessment,
  });

  factory NeedModel.fromEntity(NeedEntity entity) {
    return NeedModel(
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
      submittedByName: entity.submittedByName,
      assignedTo: entity.assignedTo,
      assignedVolunteerIds: entity.assignedVolunteerIds,
      rejectedBy: entity.rejectedBy,
      matchReason: entity.matchReason,
      ngoId: entity.ngoId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      scaleAssessment: entity.scaleAssessment,
    );
  }

  factory NeedModel.fromJson(Map<String, dynamic> json, String id) {
    return NeedModel(
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
      status: json['status'] as String? ?? 'RAW',
      submittedBy: json['submittedBy'] as String? ?? '',
      submittedByName: json['submittedByName'] as String? ?? 'Unknown',
      assignedTo: json['assignedTo'] as String?,
      assignedVolunteerIds: List<String>.from(json['assignedVolunteerIds'] as Iterable? ?? []),
      rejectedBy: List<String>.from(json['rejectedBy'] as Iterable? ?? []),
      matchReason: json['matchReason'] as String?,
      ngoId: json['ngoId'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'submittedByName': submittedByName,
      'assignedTo': assignedTo,
      'assignedVolunteerIds': assignedVolunteerIds,
      'rejectedBy': rejectedBy,
      'matchReason': matchReason,
      'ngoId': ngoId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'scaleAssessment': scaleAssessment.toJson(),
    };
  }
}
