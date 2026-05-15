
/// Modèle pour la cartographie sanitaire
class CartographieSanitaire {
  final Map<String, String> structures;
  final Map<String, int> patientsParRegion;
  final Map<String, String> zonesRisque;

  CartographieSanitaire({
    required this.structures,
    required this.patientsParRegion,
    required this.zonesRisque,
  });

  /// Ajout d'une structure
  void ajouterStructure(String region, String structure) {
    structures[region] = structure;
  }

  /// Mise à jour du nombre de patients par région
  void majPatientsRegion(String region, int nombre) {
    patientsParRegion[region] = nombre;
  }

  /// Définir une zone à risque
  void definirZoneRisque(String region, String risque) {
    zonesRisque[region] = risque;
  }
}

/// Modèle pour la gestion des stocks et ressources médicales
class StockRessource {
  final Map<String, int> stocks;
  final Map<String, String> alertesRupture;
  final Map<String, String> equipements;

  StockRessource({
    required this.stocks,
    required this.alertesRupture,
    required this.equipements,
  });

  /// Mise à jour du stock
  void majStock(String item, int quantite) {
    stocks[item] = quantite;
  }

  /// Déclencher une alerte de rupture
  void alerteRuptureStock(String item, String message) {
    alertesRupture[item] = message;
  }

  /// Ajouter un équipement
  void ajouterEquipement(String nom, String description) {
    equipements[nom] = description;
  }
}
