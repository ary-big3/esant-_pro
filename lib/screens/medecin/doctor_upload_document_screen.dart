import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class DoctorUploadDocumentScreen extends StatefulWidget {
  const DoctorUploadDocumentScreen({super.key});

  @override
  State<DoctorUploadDocumentScreen> createState() => _DoctorUploadDocumentScreenState();
}

class _DoctorUploadDocumentScreenState extends State<DoctorUploadDocumentScreen> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedFile;
  String _selectedDocumentType = 'Bilan';
  bool _isLoading = false;

  final List<String> _documentTypes = [
    'Bilan',
    'Rapport Médical',
    'Autre',
  ];

  @override
  void dispose() {
    _patientIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.single as File?;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fichier sélectionné: ${result.files.single.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (_patientIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer l\'ID du patient'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un fichier'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔵 [UPLOAD] Début upload');
      debugPrint('🔵 [UPLOAD] Patient ID: ${_patientIdController.text}');
      debugPrint('🔵 [UPLOAD] Fichier: ${_selectedFile!.path}');
      debugPrint('🔵 [UPLOAD] Type: $_selectedDocumentType');

      final response = await ApiService().multipartPost(
        '/doctor/documents/upload',
        file: _selectedFile!,
        fields: {
          'patient_id': _patientIdController.text,
          'document_type': _selectedDocumentType,
          'description': _descriptionController.text,
        },
      );

      debugPrint('🟢 [UPLOAD] Réponse: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document téléchargé avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Réinitialiser le formulaire
        _patientIdController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedFile = null;
          _selectedDocumentType = 'Bilan';
        });

        // Revenir en arrière
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      debugPrint('❌ [UPLOAD] ApiException: ${e.message}');
      debugPrint('❌ [UPLOAD] Status: ${e.statusCode}');
      debugPrint('❌ [UPLOAD] Erreurs: ${e.errors}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur API: ${e.message}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [UPLOAD] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Envoyer un Document'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône d'upload
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.file_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // ID Patient
            Text(
              'ID du Patient',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _patientIdController,
              decoration: InputDecoration(
                hintText: 'Entrez l\'ID du patient',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Type de document
            Text(
              'Type de Document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDocumentType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDocumentType = value);
                }
              },
              items: _documentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              'Description (Optionnel)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Ajoutez une description...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Sélection du fichier
            Text(
              'Fichier',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.surfaceVariant,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedFile != null
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: _selectedFile != null ? AppColors.success : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.path.split('/').last
                          : 'Cliquez pour sélectionner un fichier',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedFile != null ? AppColors.success : AppColors.textSecondary,
                        fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Bouton Envoyer
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Envoyer le Document',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
