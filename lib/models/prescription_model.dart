/// Modèle pour les ordonnances (prescriptions)
class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String prescriptionNumber;
  final String status; // active, expired, completed, cancelled
  final DateTime issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final bool canShare;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<MedicationModel> medications;
  final DoctorSummary? doctor;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.prescriptionNumber,
    required this.status,
    required this.issueDate,
    this.expiryDate,
    this.notes,
    required this.canShare,
    required this.createdAt,
    this.updatedAt,
    this.medications = const [],
    this.doctor,
  });

  /// Créer un modèle à partir de JSON
  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<MedicationModel> medications = [];
    if (json['medications'] is List) {
      medications = (json['medications'] as List)
          .map((m) => MedicationModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    DoctorSummary? doctor;
    if (json['doctor'] != null) {
      doctor = DoctorSummary.fromJson(json['doctor'] as Map<String, dynamic>);
    } else if (json['doctor_first_name'] != null) {
      doctor = DoctorSummary(
        id: json['doctor_id']?.toString() ?? '',
        firstName: json['doctor_first_name'] ?? '',
        lastName: json['doctor_last_name'] ?? '',
        speciality: json['speciality'] ?? 'Médecin',
      );
    }

    return PrescriptionModel(
      id: (json['prescription_id'] ?? json['id'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? '').toString(),
      prescriptionNumber: json['prescription_number'] ?? '',
      status: json['status'] ?? 'active',
      issueDate: _parseDateTime(json['issue_date']) ?? DateTime.now(),
      expiryDate: _parseDateTime(json['expiry_date']),
      notes: json['notes'] as String?,
      canShare: json['can_share'] == true || json['can_share'] == 1,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']),
      medications: medications,
      doctor: doctor,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'prescription_id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'prescription_number': prescriptionNumber,
      'status': status,
      'issue_date': issueDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
      'can_share': canShare,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'medications': medications.map((m) => m.toJson()).toList(),
    };
  }

  /// Parser DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Vérifier si l'ordonnance est expirée
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Vérifier si l'ordonnance est active
  bool get isActive => status == 'active' && !isExpired;

  /// Copie
  PrescriptionModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? prescriptionNumber,
    String? status,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    bool? canShare,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MedicationModel>? medications,
    DoctorSummary? doctor,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      prescriptionNumber: prescriptionNumber ?? this.prescriptionNumber,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      canShare: canShare ?? this.canShare,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medications: medications ?? this.medications,
      doctor: doctor ?? this.doctor,
    );
  }
}

/// Modèle pour les médicaments
class MedicationModel {
  final String id;
  final String name;
  final String dosage;
  final String unit;
  final String frequency;
  final String? duration;
  final String? route;
  final String? specialInstructions;
  final bool isEssential;

  MedicationModel({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.frequency,
    this.duration,
    this.route,
    this.specialInstructions,
    required this.isEssential,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: (json['medication_id'] ?? json['id'] ?? '').toString(),
      name: json['medication_name'] ?? '',
      dosage: json['dosage']?.toString() ?? '',
      unit: json['dosage_unit'] ?? 'mg',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] as String?,
      route: json['route_of_administration'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      isEssential: json['is_essential'] == true || json['is_essential'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication_id': id,
      'medication_name': name,
      'dosage': dosage,
      'dosage_unit': unit,
      'frequency': frequency,
      'duration': duration,
      'route_of_administration': route,
      'special_instructions': specialInstructions,
      'is_essential': isEssential,
    };
  }
}

/// Résumé du médecin
class DoctorSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String speciality;

  DoctorSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.speciality,
  });

  factory DoctorSummary.fromJson(Map<String, dynamic> json) {
    return DoctorSummary(
      id: (json['doctor_id'] ?? json['id'] ?? '').toString(),
      firstName: json['first_name'] ?? json['doctor_first_name'] ?? '',
      lastName: json['last_name'] ?? json['doctor_last_name'] ?? '',
      speciality: json['speciality'] ?? 'Médecin',
    );
  }

  String get fullName => '$firstName $lastName';
}
