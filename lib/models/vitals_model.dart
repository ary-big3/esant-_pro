/// Modèle pour les constantes vitales enregistrées par les infirmières
class VitalsModel {
  final String id;
  final String patientId;
  final String nurseId;
  final double temperature; // en °C
  final int tensionSystolique; // mmHg
  final int tensionDiastolique; // mmHg
  final int frequenceCardiaque; // bpm
  final int frequenceRespiratoire; // rpm
  final double saturOxygene; // %O2
  final double? poids; // kg
  final double? taille; // cm
  final String? notes;
  final DateTime recordedAt;
  final DateTime createdAt;
  DateTime? updatedAt;

  VitalsModel({
    required this.id,
    required this.patientId,
    required this.nurseId,
    required this.temperature,
    required this.tensionSystolique,
    required this.tensionDiastolique,
    required this.frequenceCardiaque,
    required this.frequenceRespiratoire,
    required this.saturOxygene,
    this.poids,
    this.taille,
    this.notes,
    required this.recordedAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Créer un VitalsModel à partir d'un JSON
  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    // Mapper les champs de l'API vers le modèle
    // L'API retourne: vital_sign_id, measurement_date, temperature_celsius, etc.
    // Le modèle utilise: id, recordedAt, temperature, etc.
    
    return VitalsModel(
      // Mapper vital_sign_id → id
      id: (json['vital_sign_id'] ?? json['id'] ?? '').toString(),
      
      // Mapper patient_id (les deux utilisent le même nom)
      patientId: (json['patient_id'] ?? 0).toString(),
      
      // Mapper nurse_id (les deux utilisent le même nom)
      nurseId: (json['nurse_id'] ?? 0).toString(),
      
      // Mapper temperature_celsius → temperature
      temperature: _toDouble(json['temperature_celsius'] ?? json['temperature']) ?? 0.0,
      
      // Mapper systolic_pressure → tensionSystolique
      tensionSystolique: _toInt(json['systolic_pressure'] ?? json['tension_systolique']) ?? 0,
      
      // Mapper diastolic_pressure → tensionDiastolique
      tensionDiastolique: _toInt(json['diastolic_pressure'] ?? json['tension_diastolique']) ?? 0,
      
      // Mapper pulse_bpm → frequenceCardiaque
      frequenceCardiaque: _toInt(json['pulse_bpm'] ?? json['frequence_cardiaque']) ?? 0,
      
      // Mapper respiratory_rate → frequenceRespiratoire
      frequenceRespiratoire: _toInt(json['respiratory_rate'] ?? json['frequence_respiratoire']) ?? 0,
      
      // Mapper oxygen_saturation → saturOxygene
      saturOxygene: _toDouble(json['oxygen_saturation'] ?? json['satur_oxygene']) ?? 0.0,
      
      // Mapper weight_kg → poids
      poids: _toDouble(json['weight_kg'] ?? json['poids']),
      
      // Mapper height_cm → taille
      taille: _toDouble(json['height_cm'] ?? json['taille']),
      
      // Notes
      notes: json['notes'] as String?,
      
      // Mapper measurement_date → recordedAt
      recordedAt: _parseDateTime(json['measurement_date'] ?? json['recorded_at']) ?? DateTime.now(),
      
      // created_at
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      
      // updated_at
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Helper pour parser les dates
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

  /// Helper pour convertir en double de manière sûre
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Helper pour convertir en int de manière sûre
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convertir un VitalsModel en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'nurse_id': nurseId,
      'temperature': temperature,
      'tension_systolique': tensionSystolique,
      'tension_diastolique': tensionDiastolique,
      'frequence_cardiaque': frequenceCardiaque,
      'frequence_respiratoire': frequenceRespiratoire,
      'satur_oxygene': saturOxygene,
      'poids': poids,
      'taille': taille,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie avec des modifications
  VitalsModel copyWith({
    String? id,
    String? patientId,
    String? nurseId,
    double? temperature,
    int? tensionSystolique,
    int? tensionDiastolique,
    int? frequenceCardiaque,
    int? frequenceRespiratoire,
    double? saturOxygene,
    double? poids,
    double? taille,
    String? notes,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VitalsModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      nurseId: nurseId ?? this.nurseId,
      temperature: temperature ?? this.temperature,
      tensionSystolique: tensionSystolique ?? this.tensionSystolique,
      tensionDiastolique: tensionDiastolique ?? this.tensionDiastolique,
      frequenceCardiaque: frequenceCardiaque ?? this.frequenceCardiaque,
      frequenceRespiratoire: frequenceRespiratoire ?? this.frequenceRespiratoire,
      saturOxygene: saturOxygene ?? this.saturOxygene,
      poids: poids ?? this.poids,
      taille: taille ?? this.taille,
      notes: notes ?? this.notes,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
