enum RendezvousStatus { confirme, enAttente, annule, termine, absent }

extension RendezvousStatusExtension on RendezvousStatus {
  String get label {
    switch (this) {
      case RendezvousStatus.confirme:
        return 'Confirmé';
      case RendezvousStatus.enAttente:
        return 'En attente';
      case RendezvousStatus.annule:
        return 'Annulé';
      case RendezvousStatus.termine:
        return 'Terminé';
      case RendezvousStatus.absent:
        return 'Absent';
    }
  }

  String get couleur {
    switch (this) {
      case RendezvousStatus.confirme:
        return '#10B981';
      case RendezvousStatus.enAttente:
        return '#F59E0B';
      case RendezvousStatus.annule:
        return '#EF4444';
      case RendezvousStatus.termine:
        return '#6B7280';
      case RendezvousStatus.absent:
        return '#EF4444';
    }
  }
}

enum TypeRendezvous { consultation, urgence, suivi, teleconsultation, examen }

extension TypeRendezvousExtension on TypeRendezvous {
  String get label {
    switch (this) {
      case TypeRendezvous.consultation:
        return 'Consultation';
      case TypeRendezvous.urgence:
        return 'Urgence';
      case TypeRendezvous.suivi:
        return 'Suivi';
      case TypeRendezvous.teleconsultation:
        return 'Téléconsultation';
      case TypeRendezvous.examen:
        return 'Examen';
    }
  }
}

class RendezvousModel {
  final String id;
  final String patientId;
  final String patientNom;
  final String medecinId;
  final String medecinNom;
  final String? medecinSpecialite;
  final String? hopitalId;
  final String? hopitalNom;
  final DateTime dateHeure;
  final int dureeMinutes;
  final TypeRendezvous type;
  final RendezvousStatus status;
  final String? motif;
  final String? notes;
  final bool rappelEnvoye;
  final DateTime createdAt;

  RendezvousModel({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.medecinId,
    required this.medecinNom,
    this.medecinSpecialite,
    this.hopitalId,
    this.hopitalNom,
    required this.dateHeure,
    this.dureeMinutes = 30,
    required this.type,
    this.status = RendezvousStatus.enAttente,
    this.motif,
    this.notes,
    this.rappelEnvoye = false,
    required this.createdAt,
  });

  DateTime get dateFin => dateHeure.add(Duration(minutes: dureeMinutes));

  bool get estAVenir => dateHeure.isAfter(DateTime.now());

  bool get estAujourdhui {
    final now = DateTime.now();
    return dateHeure.year == now.year &&
        dateHeure.month == now.month &&
        dateHeure.day == now.day;
  }

  factory RendezvousModel.fromJson(Map<String, dynamic> json) {
    return RendezvousModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientNom: json['patient_nom'] ?? '',
      medecinId: json['medecin_id'] ?? '',
      medecinNom: json['medecin_nom'] ?? '',
      medecinSpecialite: json['medecin_specialite'],
      hopitalId: json['hopital_id'],
      hopitalNom: json['hopital_nom'],
      dateHeure: DateTime.parse(json['date_heure'] ?? DateTime.now().toIso8601String()),
      dureeMinutes: json['duree_minutes'] ?? 30,
      type: TypeRendezvous.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TypeRendezvous.consultation,
      ),
      status: RendezvousStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RendezvousStatus.enAttente,
      ),
      motif: json['motif'],
      notes: json['notes'],
      rappelEnvoye: json['rappel_envoye'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_nom': patientNom,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'medecin_specialite': medecinSpecialite,
      'hopital_id': hopitalId,
      'hopital_nom': hopitalNom,
      'date_heure': dateHeure.toIso8601String(),
      'duree_minutes': dureeMinutes,
      'type': type.name,
      'status': status.name,
      'motif': motif,
      'notes': notes,
      'rappel_envoye': rappelEnvoye,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
