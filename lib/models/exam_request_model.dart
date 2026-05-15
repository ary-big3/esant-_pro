/// Modèle pour une demande d'examen du médecin au laboratoire
class ExamRequestModel {
  final String id;
  final String patientId;
  final String patientNom;
  final String? patientPrenom;
  final String medecinId;
  final String medecinNom;
  final String? medecinPrenom;
  final String specialite;
  final String hopitalId;
  final String hopitalNom;
  final DateTime dateCreation;
  final DateTime? dateExamenPrevue;
  final List<String> examensPrescrits;
  final String? observations;
  final String? urgence; // 'normal', 'urgent', 'tres_urgent'
  final ExamRequestStatus status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String laboratoireId;
  final String laboratoireNom;
  final String laboratoireType; // 'Biochimie', 'Radiologie', etc.
  final DateTime? dateReception;
  final List<ExamResultModel> resultats;

  ExamRequestModel({
    required this.id,
    required this.patientId,
    required this.patientNom,
    this.patientPrenom,
    required this.medecinId,
    required this.medecinNom,
    this.medecinPrenom,
    required this.specialite,
    required this.hopitalId,
    required this.hopitalNom,
    required this.dateCreation,
    this.dateExamenPrevue,
    required this.examensPrescrits,
    this.observations,
    this.urgence = 'normal',
    this.status = ExamRequestStatus.pending,
    required this.laboratoireId,
    required this.laboratoireNom,
    required this.laboratoireType,
    this.dateReception,
    this.resultats = const [],
  });

  bool get estPendente => status == ExamRequestStatus.pending;
  bool get estEnCours => status == ExamRequestStatus.inProgress;
  bool get estComplete => status == ExamRequestStatus.completed;
  bool get estAnnulee => status == ExamRequestStatus.cancelled;

  factory ExamRequestModel.fromJson(Map<String, dynamic> json) {
    return ExamRequestModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientNom: json['patient_nom'] ?? '',
      patientPrenom: json['patient_prenom'],
      medecinId: json['medecin_id'] ?? '',
      medecinNom: json['medecin_nom'] ?? '',
      medecinPrenom: json['medecin_prenom'],
      specialite: json['specialite'] ?? '',
      hopitalId: json['hopital_id'] ?? '',
      hopitalNom: json['hopital_nom'] ?? '',
      dateCreation: DateTime.parse(json['date_creation'] ?? DateTime.now().toIso8601String()),
      dateExamenPrevue: json['date_examen_prevue'] != null 
          ? DateTime.parse(json['date_examen_prevue']) 
          : null,
      examensPrescrits: List<String>.from(json['examens_prescrits'] ?? []),
      observations: json['observations'],
      urgence: json['urgence'] ?? 'normal',
      status: ExamRequestStatus.values.byName(json['status'] ?? 'pending'),
      laboratoireId: json['laboratoire_id'] ?? '',
      laboratoireNom: json['laboratoire_nom'] ?? '',
      laboratoireType: json['laboratoire_type'] ?? '',
      dateReception: json['date_reception'] != null 
          ? DateTime.parse(json['date_reception']) 
          : null,
      resultats: (json['resultats'] as List<dynamic>?)
          ?.map((e) => ExamResultModel.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_nom': patientNom,
      'patient_prenom': patientPrenom,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'medecin_prenom': medecinPrenom,
      'specialite': specialite,
      'hopital_id': hopitalId,
      'hopital_nom': hopitalNom,
      'date_creation': dateCreation.toIso8601String(),
      'date_examen_prevue': dateExamenPrevue?.toIso8601String(),
      'examens_prescrits': examensPrescrits,
      'observations': observations,
      'urgence': urgence,
      'status': status.name,
      'laboratoire_id': laboratoireId,
      'laboratoire_nom': laboratoireNom,
      'laboratoire_type': laboratoireType,
      'date_reception': dateReception?.toIso8601String(),
      'resultats': resultats.map((e) => e.toJson()).toList(),
    };
  }
}

enum ExamRequestStatus {
  pending,      // En attente (vient d'être créée)
  inProgress,   // En cours (le laboratoire a reçu et traite)
  completed,    // Complétée (résultats disponibles)
  cancelled,    // Annulée
}

extension ExamRequestStatusExtension on ExamRequestStatus {
  String get label {
    switch (this) {
      case ExamRequestStatus.pending:
        return 'En attente';
      case ExamRequestStatus.inProgress:
        return 'En cours';
      case ExamRequestStatus.completed:
        return 'Complétée';
      case ExamRequestStatus.cancelled:
        return 'Annulée';
    }
  }

  String get couleur {
    switch (this) {
      case ExamRequestStatus.pending:
        return '#F59E0B'; // Ambre
      case ExamRequestStatus.inProgress:
        return '#3B82F6'; // Bleu
      case ExamRequestStatus.completed:
        return '#10B981'; // Vert
      case ExamRequestStatus.cancelled:
        return '#EF4444'; // Rouge
    }
  }
}

/// Modèle pour les résultats d'examen
class ExamResultModel {
  final String id;
  final String examName;
  final String resultat;
  final String? valeurMin;
  final String? valeurMax;
  final String? unite;
  final String interpretation; // 'normal', 'anormal', 'critique'
  final DateTime dateResultat;

  ExamResultModel({
    required this.id,
    required this.examName,
    required this.resultat,
    this.valeurMin,
    this.valeurMax,
    this.unite,
    this.interpretation = 'normal',
    required this.dateResultat,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    return ExamResultModel(
      id: json['id'] ?? '',
      examName: json['exam_name'] ?? '',
      resultat: json['resultat'] ?? '',
      valeurMin: json['valeur_min'],
      valeurMax: json['valeur_max'],
      unite: json['unite'],
      interpretation: json['interpretation'] ?? 'normal',
      dateResultat: DateTime.parse(json['date_resultat'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_name': examName,
      'resultat': resultat,
      'valeur_min': valeurMin,
      'valeur_max': valeurMax,
      'unite': unite,
      'interpretation': interpretation,
      'date_resultat': dateResultat.toIso8601String(),
    };
  }
}
