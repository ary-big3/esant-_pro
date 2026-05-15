import 'exam_request_model.dart';

/// Configuration des examens par spécialité et laboratoire
class LaboratoryExamMapping {
  // Mapping spécialité → laboratoire et examens
  static const Map<String, LaboratoryInfo> specialityToLaboratory = {
    'Biologie médicale': LaboratoryInfo(
      id: 2,
      nom: 'Laboratoire Central de Biologie Médicale',
      type: 'Biologie médicale',
      examens: ['NFS', 'Glycémie', 'Bilan lipidique', 'Ionogramme', 'Analyse d\'urine', 'Bilan hépatique', 'Bilan rénal'],
    ),
    'Biochimie': LaboratoryInfo(
      id: 2,
      nom: 'Laboratoire Central de Biologie Médicale',
      type: 'Biochimie',
      examens: ['Urée', 'Créatinine', 'ALAT', 'ASAT', 'CRP', 'Protéines totales', 'Dosage enzymatique'],
    ),
    'Hématologie': LaboratoryInfo(
      id: 2,
      nom: 'Laboratoire Central de Biologie Médicale',
      type: 'Hématologie',
      examens: ['NFS', 'VS', 'Groupe sanguin', 'TP/TCA'],
    ),
    'Microbiologie': LaboratoryInfo(
      id: 2,
      nom: 'Laboratoire Central de Biologie Médicale',
      type: 'Microbiologie',
      examens: ['ECBU', 'Hémoculture', 'Coproculture', 'Antibiogramme'],
    ),
    'Génétique': LaboratoryInfo(
      id: 2,
      nom: 'Laboratoire Central de Biologie Médicale',
      type: 'Génétique',
      examens: ['Test ADN', 'Caryotype', 'Test prénatal'],
    ),
    'Radiologie / Imagerie médicale': LaboratoryInfo(
      id: 3,
      nom: 'Centre de Radiologie et Imagerie Médicale',
      type: 'Radiologie / Imagerie médicale',
      examens: ['Radiographie', 'Scanner', 'IRM', 'Échographie', 'Mammographie'],
    ),
    'Cardiologie': LaboratoryInfo(
      nom: 'Explorations fonctionnelles',
      type: 'Cardiologie',
      examens: ['ECG', 'Échocardiographie', 'Holter ECG', 'Test d\'effort'],
    ),
    'Neurologie': LaboratoryInfo(
      nom: 'Neurophysiologie',
      type: 'Neurologie',
      examens: ['EEG', 'EMG', 'IRM cérébrale'],
    ),
    'Pneumologie': LaboratoryInfo(
      nom: 'Explorations respiratoires',
      type: 'Pneumologie',
      examens: ['Spirométrie', 'Gaz du sang', 'Radiographie pulmonaire'],
    ),
    'Gastro-entérologie': LaboratoryInfo(
      nom: 'Endoscopie',
      type: 'Gastro-entérologie',
      examens: ['Fibroscopie', 'Coloscopie', 'Test Helicobacter pylori'],
    ),
    'Anatomopathologie': LaboratoryInfo(
      nom: 'Laboratoire Anatomo-pathologie',
      type: 'Anatomopathologie',
      examens: ['Biopsie', 'Analyse tumorale', 'Cytologie'],
    ),
    'Oncologie': LaboratoryInfo(
      nom: 'Cancérologie',
      type: 'Oncologie',
      examens: ['Marqueurs tumoraux', 'Biopsie', 'Scanner / IRM'],
    ),
    'Endocrinologie': LaboratoryInfo(
      nom: 'Laboratoire hormonal',
      type: 'Endocrinologie',
      examens: ['TSH', 'Insuline', 'Cortisol', 'Test hormonal'],
    ),
    'Gynécologie': LaboratoryInfo(
      nom: 'Service gynécologique',
      type: 'Gynécologie',
      examens: ['Frottis', 'Échographie pelvienne', 'Test HPV'],
    ),
    'Obstétrique': LaboratoryInfo(
      nom: 'Maternité',
      type: 'Obstétrique',
      examens: ['Échographie obstétricale', 'Test grossesse', 'Monitoring fœtal'],
    ),
    'Urologie': LaboratoryInfo(
      nom: 'Service urologie',
      type: 'Urologie',
      examens: ['PSA', 'Échographie prostatique', 'ECBU'],
    ),
    'Andrologie': LaboratoryInfo(
      nom: 'Laboratoire fertilité',
      type: 'Andrologie',
      examens: ['Spermogramme', 'Testostérone'],
    ),
    'Rhumatologie': LaboratoryInfo(
      nom: 'Service / Laboratoire',
      type: 'Rhumatologie',
      examens: ['Radiographie articulaire', 'CRP', 'Facteur rhumatoïde'],
    ),
    'Orthopédie': LaboratoryInfo(
      nom: 'Service / Laboratoire',
      type: 'Orthopédie',
      examens: ['Radiographie osseuse', 'Scanner osseux'],
    ),
    'Ophtalmologie': LaboratoryInfo(
      nom: 'Service ophtalmologie',
      type: 'Ophtalmologie',
      examens: ['Test de vision', 'Fond d\'œil', 'Tonométrie'],
    ),
    'ORL': LaboratoryInfo(
      nom: 'Service ORL',
      type: 'ORL',
      examens: ['Audiogramme', 'Endoscopie ORL'],
    ),
    'Dermatologie': LaboratoryInfo(
      nom: 'Service dermatologie',
      type: 'Dermatologie',
      examens: ['Biopsie cutanée', 'Test allergique'],
    ),
    'Néphrologie': LaboratoryInfo(
      nom: 'Laboratoire / Service néphrologie',
      type: 'Néphrologie',
      examens: ['Créatinine', 'Analyse d\'urine', 'Clairance rénale'],
    ),
    'Infectiologie': LaboratoryInfo(
      nom: 'Laboratoire infectiologie',
      type: 'Infectiologie',
      examens: ['Sérologie VIH', 'Hépatite', 'Test COVID'],
    ),
    'Dentaire': LaboratoryInfo(
      nom: 'Cabinet dentaire',
      type: 'Dentaire',
      examens: ['Radio dentaire', 'Scanner dentaire', 'Bilan bucco-dentaire'],
    ),
    'Psychiatrie / Psychologie': LaboratoryInfo(
      nom: 'Service / Cabinet',
      type: 'Psychiatrie / Psychologie',
      examens: ['Évaluation psychologique', 'Tests cognitifs'],
    ),
    'Pédiatrie / Néonatologie': LaboratoryInfo(
      nom: 'Service pédiatrie',
      type: 'Pédiatrie / Néonatologie',
      examens: ['Bilan pédiatrique', 'Tests néonataux'],
    ),
    'Rééducation': LaboratoryInfo(
      nom: 'Service rééducation',
      type: 'Rééducation',
      examens: ['Test de mobilité', 'Évaluation fonctionnelle'],
    ),
    'Allergologie': LaboratoryInfo(
      nom: 'Laboratoire allergologie',
      type: 'Allergologie',
      examens: ['Test cutané allergique', 'IgE'],
    ),
    'Médecine du travail': LaboratoryInfo(
      nom: 'Service médecine du travail',
      type: 'Médecine du travail',
      examens: ['Visite médicale', 'Test aptitude'],
    ),
    'Santé publique': LaboratoryInfo(
      nom: 'Service santé publique',
      type: 'Santé publique',
      examens: ['Dépistage', 'Campagnes médicales'],
    ),
  };

  /// Récupère les infos du laboratoire pour une spécialité donnée
  static LaboratoryInfo? getLaboratoryBySpeciality(String speciality) {
    return specialityToLaboratory[speciality];
  }

  /// Récupère tous les examens disponibles pour une spécialité
  static List<String> getExamsBySpeciality(String speciality) {
    return specialityToLaboratory[speciality]?.examens ?? [];
  }

  /// Récupère le nom du laboratoire pour une spécialité
  static String? getLaboratoryNameBySpeciality(String speciality) {
    return specialityToLaboratory[speciality]?.nom;
  }

  /// Récupère le type de laboratoire pour une spécialité
  static String? getLaboratoryTypeBySpeciality(String speciality) {
    return specialityToLaboratory[speciality]?.type;
  }
}

/// Informations sur un laboratoire
class LaboratoryInfo {
  final int? id;
  final String nom;
  final String type;
  final List<String> examens;

  const LaboratoryInfo({
    this.id,
    required this.nom,
    required this.type,
    required this.examens,
  });
}

/// Modèle pour un laboratoire
class LaboratoryModel {
  final String id;
  final String nom;
  final String type; // Biochimie, Radiologie, etc.
  final String hopitalId;
  final String hopitalNom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final List<String> examensDisponibles;
  final List<ExamRequestModel> demandesEnCours;
  final bool estActif;

  LaboratoryModel({
    required this.id,
    required this.nom,
    required this.type,
    required this.hopitalId,
    required this.hopitalNom,
    this.adresse,
    this.telephone,
    this.email,
    this.examensDisponibles = const [],
    this.demandesEnCours = const [],
    this.estActif = true,
  });

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) {
    return LaboratoryModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      type: json['type'] ?? '',
      hopitalId: json['hopital_id'] ?? '',
      hopitalNom: json['hopital_nom'] ?? '',
      adresse: json['adresse'],
      telephone: json['telephone'],
      email: json['email'],
      examensDisponibles: List<String>.from(json['examens_disponibles'] ?? []),
      estActif: json['est_actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'hopital_id': hopitalId,
      'hopital_nom': hopitalNom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'examens_disponibles': examensDisponibles,
      'est_actif': estActif,
    };
  }
}

// Import nécessaire à ajouter en haut du fichier
// import 'exam_request_model.dart';
