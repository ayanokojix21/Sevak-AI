enum CrossNgoTaskStatus { requested, accepted, inProgress, completed, cancelled }

class CrossNgoTaskEntity {
  final String id;
  final String needId;
  final String sourceNgoId;
  final String volunteerNgoId;
  final String? volunteerUid;
  final bool volunteerConsentGiven;
  final CrossNgoTaskStatus status;

  CrossNgoTaskEntity({
    required this.id,
    required this.needId,
    required this.sourceNgoId,
    required this.volunteerNgoId,
    this.volunteerUid,
    required this.volunteerConsentGiven,
    required this.status,
  });
}
