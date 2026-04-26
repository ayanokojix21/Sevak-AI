import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ImpactStoryEntity extends Equatable {
  final String id;
  final String needId;
  final String ngoId;
  final String headline;
  final String story;
  final String? beforeImageUrl;
  final String? afterImageUrl;
  final DateTime createdAt;

  const ImpactStoryEntity({
    required this.id,
    required this.needId,
    required this.ngoId,
    required this.headline,
    required this.story,
    this.beforeImageUrl,
    this.afterImageUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, needId, ngoId, headline, story, beforeImageUrl, afterImageUrl, createdAt];
}

class ImpactStoryModel extends ImpactStoryEntity {
  const ImpactStoryModel({
    required super.id,
    required super.needId,
    required super.ngoId,
    required super.headline,
    required super.story,
    super.beforeImageUrl,
    super.afterImageUrl,
    required super.createdAt,
  });

  factory ImpactStoryModel.fromJson(Map<String, dynamic> json, String id) {
    return ImpactStoryModel(
      id: id,
      needId: json['needId'] as String? ?? '',
      ngoId: json['ngoId'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      story: json['story'] as String? ?? '',
      beforeImageUrl: json['beforeImageUrl'] as String?,
      afterImageUrl: json['afterImageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'needId': needId,
      'ngoId': ngoId,
      'headline': headline,
      'story': story,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
