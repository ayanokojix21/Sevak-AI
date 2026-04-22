import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ngo_entity.dart';

class NgoModel extends NgoEntity {
  const NgoModel({
    required super.id,
    required super.name,
    required super.status,
    required super.createdAt,
    super.volunteerCount = 0,
  });

  factory NgoModel.fromJson(Map<String, dynamic> json, String id) {
    return NgoModel(
      id: id,
      name: json['name'] as String? ?? 'Unnamed NGO',
      status: json['status'] as String? ?? 'pending',
      volunteerCount: json['volunteerCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'volunteerCount': volunteerCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
