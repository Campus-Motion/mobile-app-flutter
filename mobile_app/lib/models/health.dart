class HealthData {
  final String born; // ISO8601 date YYYY-MM-DD
  final double? weightKg;
  final double? heightCm;
  final String? sensitiveData;
  final int? clientKeyVersion;
  final DateTime? consentGivenAt;
  final String? retainUntil;
  final DateTime? deletionRequestedAt;

  HealthData({
    required this.born,
    this.weightKg,
    this.heightCm,
    this.sensitiveData,
    this.clientKeyVersion,
    this.consentGivenAt,
    this.retainUntil,
    this.deletionRequestedAt,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      born: json['born'] as String? ?? '1998-11-05',
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      heightCm: json['height_cm'] != null ? (json['height_cm'] as num).toDouble() : null,
      sensitiveData: json['sensitive_data'] as String?,
      clientKeyVersion: json['client_key_version'] as int?,
      consentGivenAt: json['consent_given_at'] != null 
          ? DateTime.parse(json['consent_given_at'] as String) 
          : null,
      retainUntil: json['retain_until'] as String?,
      deletionRequestedAt: json['deletion_requested_at'] != null 
          ? DateTime.parse(json['deletion_requested_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'born': born,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (sensitiveData != null) 'sensitive_data': sensitiveData,
      if (clientKeyVersion != null) 'client_key_version': clientKeyVersion,
      if (consentGivenAt != null) 'consent_given_at': consentGivenAt!.toIso8601String(),
      if (retainUntil != null) 'retain_until': retainUntil,
    };
  }
}
