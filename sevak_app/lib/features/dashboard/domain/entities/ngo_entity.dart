import 'package:equatable/equatable.dart';

/// Represents a registered NGO in the SevakAI platform.
class NgoEntity extends Equatable {
  final String id;
  final String name;
  final String coordinatorUid;
  final String city;

  const NgoEntity({
    required this.id,
    required this.name,
    required this.coordinatorUid,
    required this.city,
  });

  @override
  List<Object?> get props => [id, name, coordinatorUid, city];
}
