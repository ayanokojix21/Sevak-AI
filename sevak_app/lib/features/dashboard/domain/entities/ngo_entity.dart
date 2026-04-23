import 'package:equatable/equatable.dart';

/// Single source of truth for NGO entity across the entire app.
/// Merged from both dashboard and ngos feature entities.
class NgoEntity extends Equatable {
  final String id;
  final String name;
  final String status; // 'pending', 'active', 'suspended'
  final String description;
  final String adminUid;
  final String coordinatorUid;
  final String city;
  final double hqLat;
  final double hqLng;
  final int volunteerCount;
  final List<String> operatingAreas;
  final List<String> sharedSkillCategories;
  final DateTime createdAt;

  const NgoEntity({
    required this.id,
    required this.name,
    this.status = 'pending',
    this.description = '',
    this.adminUid = '',
    this.coordinatorUid = '',
    this.city = '',
    this.hqLat = 0.0,
    this.hqLng = 0.0,
    this.volunteerCount = 0,
    this.operatingAreas = const [],
    this.sharedSkillCategories = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id, name, status, description, adminUid, coordinatorUid,
        city, hqLat, hqLng, volunteerCount, operatingAreas,
        sharedSkillCategories, createdAt,
      ];
}
