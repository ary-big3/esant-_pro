import 'user_model.dart';

class PatientModel extends UserModel {
  final String? nfcCardId;
  final String? groupeSanguin;
  final List<String> allergies;
  final List<String> antecedents;
  final List<String> antecedentsFamiliaux;
  final List<String> maladiesChroniques;
  final String? numeroSecuriteSociale;
  final String? personneUrgence;
  final String? telephoneUrgence;
  final double? poids;
  final double? taille;

  PatientModel({
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
    this.nfcCardId,
    this.groupeSanguin,
    this.allergies = const [],
    this.antecedents = const [],
    this.antecedentsFamiliaux = const [],
    this.maladiesChroniques = const [],
    this.numeroSecuriteSociale,
    this.personneUrgence,
    this.telephoneUrgence,
    this.poids,
    this.taille,
  }) : super(role: UserRole.patient);

  double? get imc {
    if (poids != null && taille != null && taille! > 0) {
      final tailleEnMetres = taille! / 100;
      return poids! / (tailleEnMetres * tailleEnMetres);
    }
    return null;
  }

  String get imcCategorie {
    if (imc == null) return 'Non calculé';
    if (imc! < 18.5) return 'Insuffisance pondérale';
    if (imc! < 25) return 'Poids normal';
    if (imc! < 30) return 'Surpoids';
    if (imc! < 35) return 'Obésité modérée';
    if (imc! < 40) return 'Obésité sévère';
    return 'Obésité morbide';
  }

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
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
      nfcCardId: json['nfc_card_id'],
      groupeSanguin: json['groupe_sanguin'],
      allergies: List<String>.from(json['allergies'] ?? []),
      antecedents: List<String>.from(json['antecedents'] ?? []),
      antecedentsFamiliaux: List<String>.from(json['antecedents_familiaux'] ?? []),
      maladiesChroniques: List<String>.from(json['maladies_chroniques'] ?? []),
      numeroSecuriteSociale: json['numero_securite_sociale'],
      personneUrgence: json['personne_urgence'],
      telephoneUrgence: json['telephone_urgence'],
      poids: json['poids']?.toDouble(),
      taille: json['taille']?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'nfc_card_id': nfcCardId,
      'groupe_sanguin': groupeSanguin,
      'allergies': allergies,
      'antecedents': antecedents,
      'antecedents_familiaux': antecedentsFamiliaux,
      'maladies_chroniques': maladiesChroniques,
      'numero_securite_sociale': numeroSecuriteSociale,
      'personne_urgence': personneUrgence,
      'telephone_urgence': telephoneUrgence,
      'poids': poids,
      'taille': taille,
    };
  }
}
