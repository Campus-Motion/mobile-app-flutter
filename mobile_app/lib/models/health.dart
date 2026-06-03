import 'dart:convert';

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

  factory HealthData.fromJson(Map<String, dynamic> jsonMap) {
    double? wKg = _parseDouble(jsonMap['weight_kg']);
    double? hCm = _parseDouble(jsonMap['height_cm']);

    if (jsonMap['sensitive_data'] != null) {
      try {
        final sensitive = json.decode(jsonMap['sensitive_data']);
        if (sensitive['weight_kg'] != null) wKg = _parseDouble(sensitive['weight_kg']);
        if (sensitive['height_cm'] != null) hCm = _parseDouble(sensitive['height_cm']);
      } catch (_) {}
    }

    return HealthData(
      born: DateTime.tryParse(jsonMap['born'] as String? ?? '1998-11-05').toString(),
      weightKg: wKg,
      heightCm: hCm,
      sensitiveData: jsonMap['sensitive_data'] as String?,
      clientKeyVersion: jsonMap['client_key_version'] as int?,
      consentGivenAt: jsonMap['consent_given_at'] != null 
          ? DateTime.parse(jsonMap['consent_given_at'] as String) 
          : null,
      retainUntil: jsonMap['retain_until'] as String?,
      deletionRequestedAt: jsonMap['deletion_requested_at'] != null 
          ? DateTime.parse(jsonMap['deletion_requested_at'] as String) 
          : null,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> sensitiveMap = {};
    if (weightKg != null) sensitiveMap['weight_kg'] = weightKg;
    if (heightCm != null) sensitiveMap['height_cm'] = heightCm;

    return {
      'born': born,
      'sensitive_data': json.encode(sensitiveMap),
      'client_key_version': clientKeyVersion ?? 1,
      if (consentGivenAt != null) 'consent_given_at': consentGivenAt!.toUtc().toIso8601String(),
      if (retainUntil != null) 'retain_until': retainUntil,
    };
  }
}

