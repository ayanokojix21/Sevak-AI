class InviteCodeEntity {
  final String code;
  final String ngoId;
  final String targetRole; // 'CO' or 'VL'
  final bool isSingleUse;

  const InviteCodeEntity({
    required this.code,
    required this.ngoId,
    required this.targetRole,
    required this.isSingleUse,
  });

  factory InviteCodeEntity.fromJson(Map<String, dynamic> json) {
    return InviteCodeEntity(
      code: json['code'] as String? ?? '',
      ngoId: json['ngoId'] as String? ?? '',
      targetRole: json['targetRole'] as String? ?? 'VL',
      isSingleUse: json['isSingleUse'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'ngoId': ngoId,
      'targetRole': targetRole,
      'isSingleUse': isSingleUse,
    };
  }
}
