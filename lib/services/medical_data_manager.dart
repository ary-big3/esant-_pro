/// Service de gestion des données médicales du patient
/// Permet de stocker et récupérer les informations médicales de chaque patient/enfant

class MedicalDataManager {
  // Format: {patientId: {medicalData}}
  static final Map<String, Map<String, dynamic>> _medicalData = {
    'PAT-2026-0001': {
      'nom': 'Amadou Diallo',
      'dateNaissance': '15/03/1985',
      'sexe': 'Masculin',
      'groupeSanguin': 'A+',
      'numeroSecuriste': '1850315******',
      'antecedentsMedicaux': 'Appendicectomie en 2018, Pneumonie en 2020',
      'antecedentsFamiliaux': 'Diabète (grand-mère), Hypertension (père)',
      'antecedents': ['Hypertension', 'Diabète Type 2', 'Asthme'],
      'allergies': ['Pénicilline', 'Arachides'],
      'maladieCchronique': ['Hypertension', 'Diabète Type 2', 'Asthme'],
    },
    'PAT-2026-0002': {
      'nom': 'Mohamed Diallo',
      'dateNaissance': '15/03/2018',
      'sexe': 'Masculin',
      'groupeSanguin': 'O+',
      'numeroSecuriste': '1800315******',
      'antecedentsMedicaux': 'Pneumonie en 2019',
      'antecedentsFamiliaux': 'Asthme (mère)',
      'antecedents': ['Asthme léger', 'Allergie arachides'],
      'allergies': ['Arachides', 'Aspirine'],
      'maladieCchronique': [],
    },
    'PAT-2026-0003': {
      'nom': 'Aïssatou Diallo',
      'dateNaissance': '20/07/2021',
      'sexe': 'Féminin',
      'groupeSanguin': 'A+',
      'numeroSecuriste': '1210720******',
      'antecedentsMedicaux': '',
      'antecedentsFamiliaux': 'Eczéma (mère)',
      'antecedents': ['Eczéma'],
      'allergies': ['Lait de vache'],
      'maladieCchronique': [],
    },
  };

  static Map<String, dynamic> getMedicalData(String patientId) {
    return _medicalData[patientId] ?? _getDefaultData();
  }

  static void saveMedicalData(String patientId, Map<String, dynamic> data) {
    _medicalData[patientId] = data;
  }

  static void updateMedicalData(String patientId, Map<String, dynamic> updates) {
    if (_medicalData.containsKey(patientId)) {
      _medicalData[patientId]?.addAll(updates);
    } else {
      _medicalData[patientId] = updates;
    }
  }

  static Map<String, dynamic> _getDefaultData() {
    return {
      'nom': 'Patient',
      'dateNaissance': '',
      'sexe': '',
      'groupeSanguin': '',
      'numeroSecuriste': '',
      'antecedentsMedicaux': '',
      'antecedentsFamiliaux': '',
      'antecedents': [],
      'allergies': [],
      'maladieCchronique': [],
    };
  }

  /// Récupère l'ID patient en fonction du nom/enfant
  static String getPatientId({String? childName, String? childId}) {
    if (childId != null) return childId;
    if (childName == 'Mohamed Diallo') return 'PAT-2026-0002';
    if (childName == 'Aïssatou Diallo') return 'PAT-2026-0003';
    return 'PAT-2026-0001';
  }
}
