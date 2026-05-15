
/// Modèle pour la gestion de la sécurité et de l'audit
class SecurityAudit {
  final List<String> incidents;
  final List<String> sauvegardes;
  final List<String> restaurations;
  final List<String> audits;

  SecurityAudit({
    required this.incidents,
    required this.sauvegardes,
    required this.restaurations,
    required this.audits,
  });

  /// Enregistrement d'un incident
  void enregistrerIncident(String incident) {
    incidents.add(incident);
  }

  /// Sauvegarde des données
  void sauvegarder(String sauvegarde) {
    sauvegardes.add(sauvegarde);
  }

  /// Restauration des données
  void restaurer(String restauration) {
    restaurations.add(restauration);
  }

  /// Audit technique
  void auditer(String audit) {
    audits.add(audit);
  }
}

/// Modèle pour la gestion du consentement et de la révocation d'accès
class Consentement {
  final String patientId;
  final List<String> accesAutorises;
  final List<String> accesRevokes;

  Consentement({
    required this.patientId,
    required this.accesAutorises,
    required this.accesRevokes,
  });

  /// Autoriser l'accès à un acteur
  void autoriserAcces(String acteur) {
    accesAutorises.add(acteur);
  }

  /// Révoquer l'accès à un acteur
  void revoquerAcces(String acteur) {
    accesRevokes.add(acteur);
    accesAutorises.remove(acteur);
  }
}
