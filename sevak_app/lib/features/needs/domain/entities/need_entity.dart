import 'package:equatable/equatable.dart';

class NeedEntity extends Equatable {
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
  final String? assignedTo;
  final String? matchReason;
  final String ngoId;
  final DateTime createdAt;

  const NeedEntity({
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
    this.assignedTo,
    this.matchReason,
    required this.ngoId,
    required this.createdAt,
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
        assignedTo,
        matchReason,
        ngoId,
        createdAt,
      ];
}
