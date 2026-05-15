import 'package:flutter/material.dart';
import '../patient/patient_medical_history_screen.dart';

/// Écran pour que le médecin édite les antécédents médicaux d'un patient
class DoctorPatientMedicalHistoryScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final Map<String, dynamic>? initialData;

  const DoctorPatientMedicalHistoryScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    this.initialData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Réutilise PatientMedicalHistoryScreen avec isReadOnly: false pour que le médecin puisse éditer
    return PatientMedicalHistoryScreen(
      patientIdForDoctor: patientId,
      childName: patientName,
      initialData: initialData,
      isReadOnly: false, // Le médecin peut éditer
    );
  }
}
