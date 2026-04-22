import 'package:equatable/equatable.dart';

class NgoEntity extends Equatable {
  final String id;
  final String name;
  final String status; // 'pending', 'active', 'suspended'
  final DateTime createdAt;
  final int volunteerCount;

  const NgoEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.volunteerCount = 0,
  });

  @override
  List<Object?> get props => [id, name, status, createdAt, volunteerCount];
}
