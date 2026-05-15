class MedicalDocumentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final String filePath;
  final String? description;
  final DateTime uploadedAt;
  final DateTime? createdAt;

  MedicalDocumentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    required this.filePath,
    this.description,
    required this.uploadedAt,
    this.createdAt,
  });

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    return MedicalDocumentModel(
      id: json['document_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? json['full_name'] ?? '',
      documentType: json['document_type'] ?? 'Bilan',
      fileName: json['file_name'] ?? json['filename'] ?? '',
      fileUrl: json['file_url'] ?? json['file_path'] ?? '',
      filePath: json['file_path'] ?? '',
      description: json['description'],
      uploadedAt: _parseDateTime(json['uploaded_at'] ?? json['created_at']),
      createdAt: _parseDateTime(json['created_at']),
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
      'document_id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'document_type': documentType,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_path': filePath,
      'description': description,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
