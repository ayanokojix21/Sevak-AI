import 'package:equatable/equatable.dart';

class ScaleAssessment extends Equatable {
  final String severity;
  final List<String> vulnerableGroups;
  final String infrastructureDamage;
  final String estimatedScope;

  const ScaleAssessment({
    required this.severity,
    required this.vulnerableGroups,
    required this.infrastructureDamage,
    required this.estimatedScope,
  });

  @override
  List<Object?> get props => [severity, vulnerableGroups, infrastructureDamage, estimatedScope];

  factory ScaleAssessment.fromJson(Map<String, dynamic> json) {
    return ScaleAssessment(
      severity: json['severity'] as String? ?? 'UNKNOWN',
      vulnerableGroups: List<String>.from(json['vulnerableGroups'] as Iterable? ?? []),
      infrastructureDamage: json['infrastructureDamage'] as String? ?? 'UNKNOWN',
      estimatedScope: json['estimatedScope'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'severity': severity,
    'vulnerableGroups': vulnerableGroups,
    'infrastructureDamage': infrastructureDamage,
    'estimatedScope': estimatedScope,
  };

  static const empty = ScaleAssessment(
    severity: 'UNKNOWN',
    vulnerableGroups: [],
    infrastructureDamage: 'UNKNOWN',
    estimatedScope: 'Unknown',
  );
}

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
  final String submittedByName;
  final String? assignedTo;
  final List<String> assignedVolunteerIds;
  final List<String> rejectedBy;
  final String? matchReason;
  final String ngoId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ScaleAssessment scaleAssessment;

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
    this.submittedByName = 'Unknown',
    this.assignedTo,
    this.assignedVolunteerIds = const [],
    this.rejectedBy = const [],
    this.matchReason,
    required this.ngoId,
    required this.createdAt,
    DateTime? updatedAt,
    this.scaleAssessment = ScaleAssessment.empty,
  }) : updatedAt = updatedAt ?? createdAt;

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
        submittedByName,
        assignedTo,
        assignedVolunteerIds,
        rejectedBy,
        matchReason,
        ngoId,
        createdAt,
        updatedAt,
        scaleAssessment,
      ];
}
