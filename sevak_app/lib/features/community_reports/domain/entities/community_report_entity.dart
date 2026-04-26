import 'package:equatable/equatable.dart';
import '../../../needs/domain/entities/need_entity.dart';

class CommunityReportEntity extends Equatable {
  final String id;
  final String rawText;
  final String? imageUrl;
  final String location;
  final double lat;
  final double lng;
  final String needType;
  final int urgencyScore;
  final String urgencyReason;
  final int peopleAffected;
  final String status;
  final String submittedBy;
  final String targetNgoId;
  final DateTime createdAt;
  final ScaleAssessment scaleAssessment;

  const CommunityReportEntity({
    required this.id,
    required this.rawText,
    this.imageUrl,
    required this.location,
    required this.lat,
    required this.lng,
    required this.needType,
    required this.urgencyScore,
    required this.urgencyReason,
    required this.peopleAffected,
    required this.status,
    required this.submittedBy,
    required this.targetNgoId,
    required this.createdAt,
    this.scaleAssessment = ScaleAssessment.empty,
  });

  @override
  List<Object?> get props => [
        id,
        rawText,
        imageUrl,
        location,
        lat,
        lng,
        needType,
        urgencyScore,
        urgencyReason,
        peopleAffected,
        status,
        submittedBy,
        targetNgoId,
        createdAt,
        scaleAssessment,
      ];
}
