class HopitalModel {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final String region;
  final String? telephone;
  final String? email;
  final String? siteWeb;
  final double? latitude;
  final double? longitude;
  final List<String> services;
  final List<String> specialites;
  final int capaciteLits;
  final int nombreMedecins;
  final bool estPublic;
  final String? logoUrl;
  final bool estActif;

  HopitalModel({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.region,
    this.telephone,
    this.email,
    this.siteWeb,
    this.latitude,
    this.longitude,
    this.services = const [],
    this.specialites = const [],
    this.capaciteLits = 0,
    this.nombreMedecins = 0,
    this.estPublic = true,
    this.logoUrl,
    this.estActif = true,
  });

  factory HopitalModel.fromJson(Map<String, dynamic> json) {
    return HopitalModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      region: json['region'] ?? '',
      telephone: json['telephone'],
      email: json['email'],
      siteWeb: json['site_web'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      services: List<String>.from(json['services'] ?? []),
      specialites: List<String>.from(json['specialites'] ?? []),
      capaciteLits: json['capacite_lits'] ?? 0,
      nombreMedecins: json['nombre_medecins'] ?? 0,
      estPublic: json['est_public'] ?? true,
      logoUrl: json['logo_url'],
      estActif: json['est_actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'region': region,
      'telephone': telephone,
      'email': email,
      'site_web': siteWeb,
      'latitude': latitude,
      'longitude': longitude,
      'services': services,
      'specialites': specialites,
      'capacite_lits': capaciteLits,
      'nombre_medecins': nombreMedecins,
      'est_public': estPublic,
      'logo_url': logoUrl,
      'est_actif': estActif,
    };
  }
}

class StockMedicamentModel {
  final String id;
  final String hopitalId;
  final String nom;
  final String? description;
  final String? categorie;
  final int quantite;
  final int seuilAlerte;
  final DateTime? dateExpiration;
  final String? fournisseur;
  final double? prixUnitaire;
  final String? unite;

  StockMedicamentModel({
    required this.id,
    required this.hopitalId,
    required this.nom,
    this.description,
    this.categorie,
    required this.quantite,
    this.seuilAlerte = 10,
    this.dateExpiration,
    this.fournisseur,
    this.prixUnitaire,
    this.unite,
  });

  bool get estEnRupture => quantite == 0;
  bool get estEnAlerte => quantite <= seuilAlerte && quantite > 0;
  bool get estExpire => dateExpiration != null && dateExpiration!.isBefore(DateTime.now());

  factory StockMedicamentModel.fromJson(Map<String, dynamic> json) {
    return StockMedicamentModel(
      id: json['id'] ?? '',
      hopitalId: json['hopital_id'] ?? '',
      nom: json['nom'] ?? '',
      description: json['description'],
      categorie: json['categorie'],
      quantite: json['quantite'] ?? 0,
      seuilAlerte: json['seuil_alerte'] ?? 10,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
      fournisseur: json['fournisseur'],
      prixUnitaire: json['prix_unitaire']?.toDouble(),
      unite: json['unite'],
    );
  }
}
