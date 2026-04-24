import 'package:equatable/equatable.dart';

/// Represents a task assigned to a volunteer (mirrors the `needs` collection doc).
class TaskEntity extends Equatable {
  final String id;
  final String description;
  final String? imageUrl;
  final String location;
  final double lat;
  final double lng;
  final String needType;
  final int urgencyScore;
  final String status; // ASSIGNED | IN_PROGRESS | COMPLETED
  final String ngoId;
  final String? matchReason;
  final String? crossNgoTaskId; // set if this is a cross-NGO task
  final String? sourceNgoName;  // human-readable source NGO (for cross-NGO badge)
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.lat,
    required this.lng,
    required this.needType,
    required this.urgencyScore,
    required this.status,
    required this.ngoId,
    this.matchReason,
    this.crossNgoTaskId,
    this.sourceNgoName,
    required this.createdAt,
  });

  bool get isCrossNgo => crossNgoTaskId != null && crossNgoTaskId!.isNotEmpty;

  @override
  List<Object?> get props => [
        id, description, imageUrl, location, lat, lng,
        needType, urgencyScore, status, ngoId,
        matchReason, crossNgoTaskId, sourceNgoName, createdAt,
      ];
}
