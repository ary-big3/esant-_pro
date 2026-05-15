class DossierMedicalModel {
  final String id;
  final String patientId;
  final DateTime dateCreation;
  final DateTime derniereMiseAJour;
  final List<ConsultationModel> consultations;
  final List<OrdonnanceModel> ordonnances;
  final List<ExamenModel> examens;
  final List<VaccinationModel> vaccinations;
  final List<HospitalisationModel> hospitalisations;
  final List<DocumentMedicalModel> documents;

  DossierMedicalModel({
    required this.id,
    required this.patientId,
    required this.dateCreation,
    required this.derniereMiseAJour,
    this.consultations = const [],
    this.ordonnances = const [],
    this.examens = const [],
    this.vaccinations = const [],
    this.hospitalisations = const [],
    this.documents = const [],
  });

  factory DossierMedicalModel.fromJson(Map<String, dynamic> json) {
    return DossierMedicalModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      dateCreation: DateTime.parse(json['date_creation'] ?? DateTime.now().toIso8601String()),
      derniereMiseAJour: DateTime.parse(json['derniere_mise_a_jour'] ?? DateTime.now().toIso8601String()),
      consultations: (json['consultations'] as List<dynamic>?)
              ?.map((e) => ConsultationModel.fromJson(e))
              .toList() ??
          [],
      ordonnances: (json['ordonnances'] as List<dynamic>?)
              ?.map((e) => OrdonnanceModel.fromJson(e))
              .toList() ??
          [],
      examens: (json['examens'] as List<dynamic>?)
              ?.map((e) => ExamenModel.fromJson(e))
              .toList() ??
          [],
      vaccinations: (json['vaccinations'] as List<dynamic>?)
              ?.map((e) => VaccinationModel.fromJson(e))
              .toList() ??
          [],
      hospitalisations: (json['hospitalisations'] as List<dynamic>?)
              ?.map((e) => HospitalisationModel.fromJson(e))
              .toList() ??
          [],
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => DocumentMedicalModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ConsultationModel {
  final String id;
  final String medecinId;
  final String medecinNom;
  final String? specialite;
  final DateTime dateConsultation;
  final String motif;
  final String? diagnostic;
  final String? observations;
  final String? prescriptions;
  final List<String> symptomes;
  final Map<String, dynamic>? constantes;
  final String? hopitalNom;

  ConsultationModel({
    required this.id,
    required this.medecinId,
    required this.medecinNom,
    this.specialite,
    required this.dateConsultation,
    required this.motif,
    this.diagnostic,
    this.observations,
    this.prescriptions,
    this.symptomes = const [],
    this.constantes,
    this.hopitalNom,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'] ?? '',
      medecinId: json['medecin_id'] ?? '',
      medecinNom: json['medecin_nom'] ?? '',
      specialite: json['specialite'],
      dateConsultation: DateTime.parse(json['date_consultation'] ?? DateTime.now().toIso8601String()),
      motif: json['motif'] ?? '',
      diagnostic: json['diagnostic'],
      observations: json['observations'],
      prescriptions: json['prescriptions'],
      symptomes: List<String>.from(json['symptomes'] ?? []),
      constantes: json['constantes'],
      hopitalNom: json['hopital_nom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'specialite': specialite,
      'date_consultation': dateConsultation.toIso8601String(),
      'motif': motif,
      'diagnostic': diagnostic,
      'observations': observations,
      'prescriptions': prescriptions,
      'symptomes': symptomes,
      'constantes': constantes,
      'hopital_nom': hopitalNom,
    };
  }
}

class OrdonnanceModel {
  final String id;
  final String consultationId;
  final String medecinId;
  final String medecinNom;
  final DateTime dateEmission;
  final DateTime? dateExpiration;
  final List<MedicamentPrescrit> medicaments;
  final String? instructions;
  final bool estRenouvelable;
  final int? nombreRenouvellements;
  final String? signatureNumerique;

  OrdonnanceModel({
    required this.id,
    required this.consultationId,
    required this.medecinId,
    required this.medecinNom,
    required this.dateEmission,
    this.dateExpiration,
    this.medicaments = const [],
    this.instructions,
    this.estRenouvelable = false,
    this.nombreRenouvellements,
    this.signatureNumerique,
  });

  factory OrdonnanceModel.fromJson(Map<String, dynamic> json) {
    return OrdonnanceModel(
      id: json['id'] ?? '',
      consultationId: json['consultation_id'] ?? '',
      medecinId: json['medecin_id'] ?? '',
      medecinNom: json['medecin_nom'] ?? '',
      dateEmission: DateTime.parse(json['date_emission'] ?? DateTime.now().toIso8601String()),
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
      medicaments: (json['medicaments'] as List<dynamic>?)
              ?.map((e) => MedicamentPrescrit.fromJson(e))
              .toList() ??
          [],
      instructions: json['instructions'],
      estRenouvelable: json['est_renouvelable'] ?? false,
      nombreRenouvellements: json['nombre_renouvellements'],
      signatureNumerique: json['signature_numerique'],
    );
  }
}

class MedicamentPrescrit {
  final String nom;
  final String dosage;
  final String frequence;
  final int dureeJours;
  final String? instructions;

  MedicamentPrescrit({
    required this.nom,
    required this.dosage,
    required this.frequence,
    required this.dureeJours,
    this.instructions,
  });

  factory MedicamentPrescrit.fromJson(Map<String, dynamic> json) {
    return MedicamentPrescrit(
      nom: json['nom'] ?? '',
      dosage: json['dosage'] ?? '',
      frequence: json['frequence'] ?? '',
      dureeJours: json['duree_jours'] ?? 0,
      instructions: json['instructions'],
    );
  }
}

class ExamenModel {
  final String id;
  final String type;
  final String nom;
  final DateTime dateExamen;
  final String? resultat;
  final String? interpretation;
  final String? medecinPrescripteur;
  final String? laboratoire;
  final String? fichierUrl;
  final bool estNormal;

  ExamenModel({
    required this.id,
    required this.type,
    required this.nom,
    required this.dateExamen,
    this.resultat,
    this.interpretation,
    this.medecinPrescripteur,
    this.laboratoire,
    this.fichierUrl,
    this.estNormal = true,
  });

  factory ExamenModel.fromJson(Map<String, dynamic> json) {
    return ExamenModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      nom: json['nom'] ?? '',
      dateExamen: DateTime.parse(json['date_examen'] ?? DateTime.now().toIso8601String()),
      resultat: json['resultat'],
      interpretation: json['interpretation'],
      medecinPrescripteur: json['medecin_prescripteur'],
      laboratoire: json['laboratoire'],
      fichierUrl: json['fichier_url'],
      estNormal: json['est_normal'] ?? true,
    );
  }
}

class VaccinationModel {
  final String id;
  final String nomVaccin;
  final DateTime dateVaccination;
  final String? lotNumero;
  final String? lieu;
  final String? medecinNom;
  final DateTime? prochainRappel;

  VaccinationModel({
    required this.id,
    required this.nomVaccin,
    required this.dateVaccination,
    this.lotNumero,
    this.lieu,
    this.medecinNom,
    this.prochainRappel,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id'] ?? '',
      nomVaccin: json['nom_vaccin'] ?? '',
      dateVaccination: DateTime.parse(json['date_vaccination'] ?? DateTime.now().toIso8601String()),
      lotNumero: json['lot_numero'],
      lieu: json['lieu'],
      medecinNom: json['medecin_nom'],
      prochainRappel: json['prochain_rappel'] != null
          ? DateTime.parse(json['prochain_rappel'])
          : null,
    );
  }
}

class HospitalisationModel {
  final String id;
  final String hopitalNom;
  final String service;
  final DateTime dateEntree;
  final DateTime? dateSortie;
  final String motif;
  final String? diagnostic;
  final String? traitement;
  final String? medecinResponsable;

  HospitalisationModel({
    required this.id,
    required this.hopitalNom,
    required this.service,
    required this.dateEntree,
    this.dateSortie,
    required this.motif,
    this.diagnostic,
    this.traitement,
    this.medecinResponsable,
  });

  factory HospitalisationModel.fromJson(Map<String, dynamic> json) {
    return HospitalisationModel(
      id: json['id'] ?? '',
      hopitalNom: json['hopital_nom'] ?? '',
      service: json['service'] ?? '',
      dateEntree: DateTime.parse(json['date_entree'] ?? DateTime.now().toIso8601String()),
      dateSortie: json['date_sortie'] != null
          ? DateTime.parse(json['date_sortie'])
          : null,
      motif: json['motif'] ?? '',
      diagnostic: json['diagnostic'],
      traitement: json['traitement'],
      medecinResponsable: json['medecin_responsable'],
    );
  }
}

class DocumentMedicalModel {
  final String id;
  final String nom;
  final String type;
  final DateTime dateAjout;
  final String? description;
  final String fichierUrl;
  final String? ajoutePar;
  final int tailleFichier;

  DocumentMedicalModel({
    required this.id,
    required this.nom,
    required this.type,
    required this.dateAjout,
    this.description,
    required this.fichierUrl,
    this.ajoutePar,
    this.tailleFichier = 0,
  });

  factory DocumentMedicalModel.fromJson(Map<String, dynamic> json) {
    return DocumentMedicalModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      type: json['type'] ?? '',
      dateAjout: DateTime.parse(json['date_ajout'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      fichierUrl: json['fichier_url'] ?? '',
      ajoutePar: json['ajoute_par'],
      tailleFichier: json['taille_fichier'] ?? 0,
    );
  }
}
