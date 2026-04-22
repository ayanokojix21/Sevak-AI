enum PartnershipStatus { pending, active, rejected }

class PartnershipEntity {
  final String id;
  final String ngoA;
  final String ngoB;
  final PartnershipStatus status;
  final List<String> sharedSkills;
  final DateTime consentDate;

  PartnershipEntity({
    required this.id,
    required this.ngoA,
    required this.ngoB,
    required this.status,
    required this.sharedSkills,
    required this.consentDate,
  });
}
