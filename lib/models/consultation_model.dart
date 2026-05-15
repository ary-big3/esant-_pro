class ConsultationModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String diagnosis;
  final String notes;
  final String consultationType;
  final DateTime consultationDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConsultationModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.diagnosis,
    required this.notes,
    required this.consultationType,
    required this.consultationDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['consultation_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? json['full_name'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      notes: json['notes'] ?? '',
      consultationType: json['consultation_type'] ?? 'En ligne',
      consultationDate: _parseDateTime(json['consultation_date']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'diagnosis': diagnosis,
      'notes': notes,
      'consultation_type': consultationType,
      'consultation_date': consultationDate.toIso8601String(),
    };
  }
}
