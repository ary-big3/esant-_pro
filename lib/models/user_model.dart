import 'package:flutter/material.dart';

enum UserRole { patient, doctor, nurse, laboratory, admin }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Médecin';
      case UserRole.nurse:
        return 'Infirmière';
      case UserRole.laboratory:
        return 'Laboratoire';
      case UserRole.admin:
        return 'Administration';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.patient:
        return Icons.person;
      case UserRole.doctor:
        return Icons.medical_information;
      case UserRole.nurse:
        return Icons.local_hospital;
      case UserRole.laboratory:
        return Icons.science;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.patient:
        return const Color(0xFF0F1A2E);
      case UserRole.doctor:
        return const Color(0xFF4CAF50);
      case UserRole.nurse:
        return const Color(0xFFFF9800);
      case UserRole.laboratory:
        return const Color(0xFF9C27B0);
      case UserRole.admin:
        return const Color(0xFFF44336);
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? adresse;
  final DateTime? dateNaissance;
  final String? sexe;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? parentId; // Pour les enfants

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.adresse,
    this.dateNaissance,
    this.sexe,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.parentId,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales => '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
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
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.patient,
      ),
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'adresse': adresse,
      'date_naissance': dateNaissance?.toIso8601String(),
      'sexe': sexe,
      'role': role.name,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'parent_id': parentId,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? adresse,
    DateTime? dateNaissance,
    String? sexe,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? parentId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      sexe: sexe ?? this.sexe,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      parentId: parentId ?? this.parentId,
    );
  }
}
