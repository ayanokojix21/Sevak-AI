import 'package:equatable/equatable.dart';

/// Represents a registered Volunteer in the SevakAI platform.
class Volunteer extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String ngoId;
  final List<String> skills;
  final int activeTasks;
  final DateTime createdAt;

  const Volunteer({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.ngoId,
    required this.skills,
    this.activeTasks = 0,
    required this.createdAt,
  });

  /// Factory constructor to create a Volunteer from Firestore JSON data
  factory Volunteer.fromJson(Map<String, dynamic> json, String documentId) {
    return Volunteer(
      uid: documentId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      ngoId: json['ngoId'] as String? ?? '',
      skills: json['skills'] != null ? List<String>.from(json['skills'] as Iterable) : [],
      activeTasks: json['activeTasks'] as int? ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
    );
  }

  /// Converts a Volunteer instance into a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'ngoId': ngoId,
      'skills': skills,
      'activeTasks': activeTasks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, phone, ngoId, skills, activeTasks, createdAt];
}
