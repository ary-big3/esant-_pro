import 'user_model.dart';

class MedecinModel extends UserModel {
  final String? matricule;
  final String? specialite;
  final String? hopitalId;
  final String? hopitalNom;
  final String? service;
  final List<String> diplomes;
  final int anneesExperience;
  final bool disponibleTeleconsultation;
  final List<String> joursDisponibles;
  final String? heureDebut;
  final String? heureFin;

  MedecinModel({
    required super.id,
    required super.email,
    required super.nom,
    required super.prenom,
    super.telephone,
    super.adresse,
    super.dateNaissance,
    super.sexe,
    super.avatarUrl,
    super.isActive,
    required super.createdAt,
    super.lastLogin,
    this.matricule,
    this.specialite,
    this.hopitalId,
    this.hopitalNom,
    this.service,
    this.diplomes = const [],
    this.anneesExperience = 0,
    this.disponibleTeleconsultation = false,
    this.joursDisponibles = const [],
    this.heureDebut,
    this.heureFin,
  }) : super(role: UserRole.doctor);

  String get titre => 'Dr. $nomComplet';

  factory MedecinModel.fromJson(Map<String, dynamic> json) {
    return MedecinModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'],
      adresse: json['adresse'],
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'])
          : null,
      sexe: json['sexe'],
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      matricule: json['matricule'],
      specialite: json['specialite'],
      hopitalId: json['hopital_id'],
      hopitalNom: json['hopital_nom'],
      service: json['service'],
      diplomes: List<String>.from(json['diplomes'] ?? []),
      anneesExperience: json['annees_experience'] ?? 0,
      disponibleTeleconsultation: json['disponible_teleconsultation'] ?? false,
      joursDisponibles: List<String>.from(json['jours_disponibles'] ?? []),
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'matricule': matricule,
      'specialite': specialite,
      'hopital_id': hopitalId,
      'hopital_nom': hopitalNom,
      'service': service,
      'diplomes': diplomes,
      'annees_experience': anneesExperience,
      'disponible_teleconsultation': disponibleTeleconsultation,
      'jours_disponibles': joursDisponibles,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    };
  }
}
