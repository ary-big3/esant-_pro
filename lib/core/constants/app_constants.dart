class AppConstants {
  static const String appName = 'E-Santé Nationale';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Plateforme Nationale E-Santé Intelligente et Sécurisée';
  
  // Rôles utilisateurs
  static const String rolePatient = 'patient';
  static const String roleMedecin = 'medecin';
  static const String roleAdmin = 'admin';

  static const String roleSystemAdmin = 'system_admin';
  
  // Statuts
  static const String statusActive = 'actif';
  static const String statusInactive = 'inactif';
  static const String statusPending = 'en_attente';
  static const String statusSuspended = 'suspendu';
  
  // Types de rendez-vous
  static const String rdvConsultation = 'consultation';
  static const String rdvUrgence = 'urgence';
  static const String rdvSuivi = 'suivi';
  
  // Régions
  static const List<String> regions = [
    'Région Nord',
    'Région Centre',
    'Région Sud',
  ];
  
  // Spécialités médicales
  static const List<String> specialites = [
    'Médecine Générale',
    'Biologie médicale',
    'Biochimie',
    'Hématologie',
    'Microbiologie',
    'Génétique',
    'Radiologie / Imagerie médicale',
    'Cardiologie',
    'Neurologie',
    'Pneumologie',
    'Gastro-entérologie',
    'Anatomopathologie',
    'Oncologie',
    'Endocrinologie',
    'Gynécologie',
    'Obstétrique',
    'Urologie',
    'Andrologie',
    'Rhumatologie',
    'Orthopédie',
    'Ophtalmologie',
    'ORL',
    'Dermatologie',
    'Néphrologie',
    'Infectiologie',
    'Dentaire',
    'Psychiatrie / Psychologie',
    'Pédiatrie / Néonatologie',
    'Rééducation',
    'Allergologie',
    'Médecine du travail',
    'Santé publique',
    'Chirurgie Générale',
    'Anesthésiologie',
    'Urgences',
  ];
  
  // Groupes sanguins
  static const List<String> groupesSanguins = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];
}

class AppAssets {
  static const String logoPath = 'assets/images/logo.png';
  static const String logoWhitePath = 'assets/images/logo_white.png';
  static const String placeholderAvatar = 'assets/images/avatar_placeholder.png';
  static const String nfcCard = 'assets/images/nfc_card.png';
  static const String emptyState = 'assets/images/empty_state.png';
}

class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String forgotPassword = '/forgot-password';
  
  // Patient
  static const String patientHome = '/patient';
  static const String patientDossier = '/patient/dossier';
  static const String patientRdv = '/patient/rdv';
  static const String patientOrdonnances = '/patient/ordonnances';
  static const String patientConsentement = '/patient/consentement';
  static const String patientProfile = '/patient/profile';
  
  // Médecin
  static const String medecinHome = '/medecin';
  static const String medecinPatients = '/medecin/patients';
  static const String medecinConsultation = '/medecin/consultation';
  static const String medecinPrescription = '/medecin/prescription';
  static const String medecinPrescribeExam = '/medecin/prescribe-exam';
  static const String medecinAgenda = '/medecin/agenda';
  static const String medecinProfile = '/medecin/profile';
  
  // Administration
  static const String adminHome = '/admin';
  static const String adminUtilisateurs = '/admin/utilisateurs';
  static const String adminStocks = '/admin/stocks';
  static const String adminRapports = '/admin/rapports';
  static const String adminAcces = '/admin/acces';
  
  // Laboratoire
  static const String laboratoryHome = '/laboratory';
  static const String laboratoryExams = '/laboratory/exams';
  static const String laboratoryResults = '/laboratory/results';
  

}
