class AllergyModel {
  final String id;
  final String patientId;
  final String allergyName;
  final String severity;
  final String? description;
  final String? reaction;
  final DateTime? diagnosedDate;
  final DateTime? createdAt;

  AllergyModel({
    required this.id,
    required this.patientId,
    required this.allergyName,
    required this.severity,
    this.description,
    this.reaction,
    this.diagnosedDate,
    this.createdAt,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
      id: json['allergy_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      allergyName: json['allergy_name'] ?? '',
      severity: json['severity'] ?? 'Modérée',
      description: json['description'],
      reaction: json['reaction'],
      diagnosedDate: _parseDateTime(json['diagnosed_date']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date is DateTime) return date;
    if (date is String && date.isNotEmpty) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'allergy_id': id,
      'patient_id': patientId,
      'allergy_name': allergyName,
      'severity': severity,
      'description': description,
      'reaction': reaction,
      'diagnosed_date': diagnosedDate?.toIso8601String(),
    };
  }
}
