
/// Modèle pour la gestion des rôles et permissions
class RolePermission {
  final String userId;
  final List<String> roles;
  final Map<String, List<String>> permissions;

  RolePermission({
    required this.userId,
    required this.roles,
    required this.permissions,
  });

  /// Attribution d'un rôle
  void ajouterRole(String role) {
    if (!roles.contains(role)) roles.add(role);
  }

  /// Suppression d'un rôle
  void supprimerRole(String role) {
    roles.remove(role);
  }

  /// Attribution d'une permission
  void ajouterPermission(String role, String permission) {
    permissions.putIfAbsent(role, () => []);
    if (!permissions[role]!.contains(permission)) permissions[role]!.add(permission);
  }

  /// Suppression d'une permission
  void supprimerPermission(String role, String permission) {
    permissions[role]?.remove(permission);
  }
}

/// Modèle pour le reporting et l'export des statistiques
class Reporting {
  final List<String> rapports;
  final List<String> exports;

  Reporting({
    required this.rapports,
    required this.exports,
  });

  /// Génération d'un rapport
  void genererRapport(String rapport) {
    rapports.add(rapport);
  }

  /// Export de données
  void exporter(String export) {
    exports.add(export);
  }
}
