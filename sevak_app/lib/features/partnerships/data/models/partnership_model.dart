import '../../domain/entities/partnership_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnershipModel extends PartnershipEntity {
  PartnershipModel({
    required super.id,
    required super.ngoA,
    required super.ngoB,
    required super.status,
    required super.sharedSkills,
    required super.consentDate,
  });

  factory PartnershipModel.fromJson(Map<String, dynamic> json, String id) {
    return PartnershipModel(
      id: id,
      ngoA: json['ngoA'] ?? '',
      ngoB: json['ngoB'] ?? '',
      status: PartnershipStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
        orElse: () => PartnershipStatus.pending,
      ),
      sharedSkills: List<String>.from(json['sharedSkills'] ?? []),
      consentDate: (json['consentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ngoA': ngoA,
      'ngoB': ngoB,
      'status': status.name,
      'sharedSkills': sharedSkills,
      'consentDate': Timestamp.fromDate(consentDate),
    };
  }
}
