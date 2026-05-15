<?php
/**
 * Gestionnaire de routage API
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/constants.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/Response.php';

class Router {
    private $method;
    private $path;
    private $controllerName;
    private $actionName;
    private $params;

    public function __construct() {
        $this->method = $_SERVER['REQUEST_METHOD'];
        $this->parseRequest();
    }

    /**
     * Parser la requête
     */
    private function parseRequest() {
        $requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        // Retirer le prefix /esante/backend/public
        $basePath = '/esante/backend/public';
        $this->path = str_replace($basePath, '', $requestUri);
        
        // Enlever les slashes inutiles
        $this->path = trim($this->path, '/');
        
        if (empty($this->path)) {
            $this->path = 'home';
        }
    }

    /**
     * Dispatcher la requête vers le bon contrôleur
     */
    public function dispatch() {
        try {
            // Ajouter les headers de sécurité
            AuthMiddleware::addSecurityHeaders();
            AuthMiddleware::handlePreflightRequest();

            // Routes publiques (sans authentification)
            if ($this->matchRoute('POST', 'auth/register')) {
                $this->callController('AuthController', 'register');
            } elseif ($this->matchRoute('POST', 'auth/login')) {
                $this->callController('AuthController', 'login');
            } elseif ($this->matchRoute('GET', 'auth/verify-token')) {
                $this->callController('AuthController', 'verifyToken');
            } elseif ($this->matchRoute('POST', 'auth/refresh-token')) {
                $this->callController('AuthController', 'refreshToken');
            }

            // Routes Patient
            elseif ($this->matchRoute('GET', 'patient/profile')) {
                $this->callController('PatientController', 'getProfile');
            } elseif ($this->matchRoute('PUT', 'patient/profile')) {
                $this->callController('PatientController', 'updateProfile');
            } elseif ($this->matchRoute('GET', 'patient/children')) {
                $this->callController('PatientController', 'getChildren');
            } elseif ($this->matchRoute('GET', 'patient/nfc-card')) {
                $this->callController('PatientController', 'getNFCCard');
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/nfc-card')) {
                $this->callController('PatientController', 'getNFCCard', ['patientId']);
            } elseif ($this->matchRoute('POST', 'patient/switch-to-child/{childPatientId}')) {
                $this->callController('PatientController', 'switchToChild', ['childPatientId']);
            } elseif ($this->matchRoute('POST', 'patient/return-to-parent')) {
                $this->callController('PatientController', 'returnToParent');
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/profile')) {
                $this->callController('PatientController', 'getPatientProfile', ['patientId']);
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/consultations')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('MedicalDossierController', 'getConsultations', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/prescriptions')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PrescriptionController', 'getPatientPrescriptionsById', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/exams')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('ExamController', 'getPatientExamsById', ['patientId', $page, $limit]);
            }

            // Routes Dossier Médical
            elseif ($this->matchRoute('GET', 'medical-dossier/{patientId}/summary')) {
                $this->callController('MedicalDossierController', 'getSummary', ['patientId']);
            } elseif ($this->matchRoute('PUT', 'medical-dossier/medical-history')) {
                $this->callController('MedicalDossierController', 'updateMedicalHistory');
            } elseif ($this->matchRoute('GET', 'medical-dossier/{patientId}/consultations')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('MedicalDossierController', 'getConsultations', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'medical-dossier/{patientId}/exams')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('MedicalDossierController', 'getExams', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'medical-dossier/{patientId}/vaccinations')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('MedicalDossierController', 'getVaccinations', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'medical-dossier/{patientId}/documents')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('MedicalDossierController', 'getDocuments', ['patientId', $page, $limit]);
            }

            // Routes Rendez-vous
            elseif ($this->matchRoute('POST', 'appointments')) {
                $this->callController('AppointmentController', 'create');
            } elseif ($this->matchRoute('GET', 'appointments/patient')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('AppointmentController', 'getPatientAppointments', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'appointments/doctor/{doctorId}')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('AppointmentController', 'getDoctorAppointments', ['doctorId', $page, $limit]);
            } elseif ($this->matchRoute('PUT', 'appointments/{appointmentId}/status')) {
                $this->callController('AppointmentController', 'updateStatus', ['appointmentId']);
            } elseif ($this->matchRoute('POST', 'appointment-requests')) {
                $this->callController('AppointmentController', 'createAppointmentRequest');
            } elseif ($this->matchRoute('PUT', 'appointments/{appointmentId}/approve')) {
                $this->callController('AppointmentController', 'approveAppointmentRequest', ['appointmentId']);
            }

            // Routes Notifications
            elseif ($this->matchRoute('GET', 'notifications')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 20;
                $this->callController('NotificationController', 'getMyNotifications', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'notifications/{notificationId}/read')) {
                $this->callController('NotificationController', 'markAsRead', ['notificationId']);
            } elseif ($this->matchRoute('GET', 'notifications/unread-count')) {
                $this->callController('NotificationController', 'getUnreadCount');
            }

            // Routes Hôpital
            elseif ($this->matchRoute('GET', 'hospital/info')) {
                $this->callController('HospitalController', 'getMainHospitalInfo');
            } elseif ($this->matchRoute('GET', 'hospital/{hospitalId}')) {
                $this->callController('HospitalController', 'getHospitalById', ['hospitalId']);
            } elseif ($this->matchRoute('GET', 'hospital/my-hospital')) {
                $this->callController('HospitalController', 'getDoctorHospital');
            } elseif ($this->matchRoute('GET', 'hospitals')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 20;
                $this->callController('HospitalController', 'getAllHospitals', [$page, $limit]);
            }

            // Routes Demandes d'Accès au Dossier Médical
            elseif ($this->matchRoute('POST', 'doctors/request-patient-access')) {
                $this->callController('DoctorController', 'sendAccessRequest');
            } elseif ($this->matchRoute('GET', 'patients/pending-requests')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PatientController', 'getPendingRequests', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'patients/requests/{requestId}/approve')) {
                $this->callController('PatientController', 'approveAccessRequest', ['requestId']);
            } elseif ($this->matchRoute('POST', 'access-requests')) {
                $this->callController('AccessRequestController', 'requestAccess');
            } elseif ($this->matchRoute('GET', 'access-requests')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 20;
                $this->callController('AccessRequestController', 'getMyAccessRequests', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'access-requests/{requestId}/approve')) {
                $this->callController('AccessRequestController', 'approveAccessRequest', ['requestId']);
            } elseif ($this->matchRoute('POST', 'access-requests/{requestId}/reject')) {
                $this->callController('AccessRequestController', 'rejectAccessRequest', ['requestId']);
            } elseif ($this->matchRoute('GET', 'access-requests/check/{patientId}')) {
                $this->callController('AccessRequestController', 'hasAccess', ['patientId']);
            }

            // Routes Ordonnances
            elseif ($this->matchRoute('POST', 'prescriptions')) {
                $this->callController('PrescriptionController', 'create');
            } elseif ($this->matchRoute('GET', 'prescriptions/patient')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PrescriptionController', 'getPatientPrescriptions', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'patient/{patientId}/prescriptions')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PrescriptionController', 'getPatientPrescriptionsById', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'prescriptions/{prescriptionId}')) {
                $this->callController('PrescriptionController', 'getPrescription', ['prescriptionId']);
            } elseif ($this->matchRoute('PUT', 'prescriptions/{prescriptionId}/status')) {
                $this->callController('PrescriptionController', 'updateStatus', ['prescriptionId']);
            }

            // Routes Examens
            elseif ($this->matchRoute('POST', 'exams')) {
                $this->callController('ExamController', 'prescribeExam');
            } elseif ($this->matchRoute('POST', 'exams/prescribe')) {
                $this->callController('ExamController', 'prescribeExam');
            } elseif ($this->matchRoute('GET', 'exams/patient')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('ExamController', 'getPatientExams', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'exams/{examId}')) {
                $this->callController('ExamController', 'getExam', ['examId']);
            } elseif ($this->matchRoute('POST', 'exams/{examId}/record-results')) {
                $this->callController('ExamController', 'recordResults', ['examId']);
            }

            // Routes Consultations
            elseif ($this->matchRoute('POST', 'consultations')) {
                $this->callController('ConsultationController', 'create');
            } elseif ($this->matchRoute('GET', 'consultations/patient')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('ConsultationController', 'getPatientConsultations', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'consultations/{consultationId}')) {
                $this->callController('ConsultationController', 'getConsultation', ['consultationId']);
            } elseif ($this->matchRoute('PUT', 'consultations/{consultationId}')) {
                $this->callController('ConsultationController', 'update', ['consultationId']);
            }

            // Routes Médecin
            elseif ($this->matchRoute('GET', 'doctor/profile')) {
                $this->callController('DoctorController', 'getProfile');
            } elseif ($this->matchRoute('POST', 'doctor/search-patients') || $this->matchRoute('POST', 'doctors/search-patients')) {
                $this->callController('DoctorController', 'searchPatients');
            } elseif ($this->matchRoute('POST', 'doctor/search-any-patient')) {
                $this->callController('DoctorController', 'searchAnyPatient');
            } elseif ($this->matchRoute('GET', 'doctor/statistics')) {
                $this->callController('DoctorController', 'getStatistics');
            } elseif ($this->matchRoute('GET', 'doctor/specialities')) {
                $this->callController('DoctorController', 'getSpecialities');
            }

            // Routes Agenda Médecin
            elseif ($this->matchRoute('GET', 'doctor/agenda')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('DoctorController', 'getAgenda', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'doctor/notifications')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('DoctorController', 'getNotifications', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'doctor/agenda/available-slots')) {
                $this->callController('DoctorController', 'getAvailableSlots');
            } elseif ($this->matchRoute('POST', 'doctor/agenda/unavailable-slot')) {
                $this->callController('DoctorController', 'createUnavailableSlot');
            } elseif ($this->matchRoute('GET', 'doctor/agenda/unavailable-slots')) {
                $this->callController('DoctorController', 'getUnavailableSlots');
            } elseif ($this->matchRoute('DELETE', 'doctor/agenda/unavailable-slot/{slotId}')) {
                $this->callController('DoctorController', 'deleteUnavailableSlot', ['slotId']);
            } elseif ($this->matchRoute('GET', 'doctor/agenda/today')) {
                $this->callController('DoctorController', 'getTodayAppointments');
            } elseif ($this->matchRoute('GET', 'doctor/agenda/by-date/{date}')) {
                $this->callController('DoctorController', 'getAppointmentsByDate', ['date']);
            }

            // Routes Demandes d'Accès Patient
            elseif ($this->matchRoute('POST', 'doctor/send-access-request')) {
                $this->callController('DoctorController', 'sendAccessRequest');
            } elseif ($this->matchRoute('GET', 'patient/pending-requests')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PatientController', 'getPendingRequests', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'patient/approve-request/{requestId}')) {
                $this->callController('PatientController', 'approveAccessRequest', ['requestId']);
            } elseif ($this->matchRoute('POST', 'patient/reject-request/{requestId}')) {
                $this->callController('PatientController', 'rejectAccessRequest', ['requestId']);
            } elseif ($this->matchRoute('GET', 'patient/consents')) {
                $this->callController('PatientController', 'getConsentedAccess');
            }

            // Routes Infirmière
            elseif ($this->matchRoute('GET', 'nurse/profile')) {
                $this->callController('NurseController', 'getProfile');
            } elseif ($this->matchRoute('POST', 'nurse/vitals')) {
                $this->callController('NurseController', 'recordVitals');
            } elseif ($this->matchRoute('GET', 'nurse/vitals/{patientId}')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('NurseController', 'getVitals', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('PUT', 'nurse/vitals/{vitalId}')) {
                $this->callController('NurseController', 'updateVitals', ['vitalId']);
            } elseif ($this->matchRoute('DELETE', 'nurse/vitals/{vitalId}')) {
                $this->callController('NurseController', 'deleteVitals', ['vitalId']);
            } elseif ($this->matchRoute('GET', 'nurse/vitals/{patientId}/latest')) {
                $this->callController('NurseController', 'getLatestVitals', ['patientId']);
            }

            // Routes Laboratoire
            elseif ($this->matchRoute('GET', 'laboratory/profile')) {
                $this->callController('LaboratoryController', 'getProfile');
            } elseif ($this->matchRoute('GET', 'laboratory/exams/pending')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('LaboratoryController', 'getPendingExams', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'laboratory/exams/in-progress')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('LaboratoryController', 'getInProgressExams', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'laboratory/prescriptions/pending')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('LaboratoryController', 'getPendingPrescriptions', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'laboratory/exams/{examId}/accept')) {
                $this->callController('LaboratoryController', 'acceptExam', ['examId']);
            } elseif ($this->matchRoute('POST', 'laboratory/exams/{examId}/reject')) {
                $this->callController('LaboratoryController', 'rejectExam', ['examId']);
            } elseif ($this->matchRoute('POST', 'laboratory/exams/{examId}/start')) {
                $this->callController('LaboratoryController', 'startExam', ['examId']);
            } elseif ($this->matchRoute('POST', 'laboratory/exams/{examId}/record-results')) {
                $this->callController('LaboratoryController', 'recordExamResults', ['examId']);
            } elseif ($this->matchRoute('POST', 'laboratory/documents/upload')) {
                $this->callController('LaboratoryController', 'uploadResultDocument');
            } elseif ($this->matchRoute('GET', 'laboratory/exams/completed')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('LaboratoryController', 'getCompletedExams', [$page, $limit]);
            }

            // Routes Médecin - Recherche et Dossier Patient
            elseif ($this->matchRoute('POST', 'doctor/patients/search')) {
                $this->callController('DoctorController', 'searchPatients');
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/dossier')) {
                $this->callController('MedicalDossierController', 'getSummary', ['patientId']);
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/consultations')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('ConsultationController', 'getPatientConsultations', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('POST', 'doctor/consultations/create')) {
                $this->callController('ConsultationController', 'create');
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/documents')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('DocumentController', 'getPatientDocuments', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('POST', 'doctor/documents/upload')) {
                $this->callController('DocumentController', 'upload');
            } elseif ($this->matchRoute('DELETE', 'doctor/documents/{documentId}/delete')) {
                $this->callController('DocumentController', 'delete', ['documentId']);
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/allergies')) {
                $this->callController('AllergyController', 'getPatientAllergies', ['patientId']);
            } elseif ($this->matchRoute('POST', 'doctor/allergies/add')) {
                $this->callController('AllergyController', 'add');
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/prescriptions')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('PrescriptionController', 'getPatientPrescriptionsById', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('GET', 'doctor/patients/{patientId}/exams')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('ExamController', 'getPatientExamsById', ['patientId', $page, $limit]);
            } elseif ($this->matchRoute('POST', 'doctor/exams/prescribe')) {
                $this->callController('ExamController', 'prescribeExam');
            } elseif ($this->matchRoute('POST', 'doctor/prescriptions/create')) {
                $this->callController('PrescriptionController', 'create');
            }

            // Routes Administration
            elseif ($this->matchRoute('GET', 'admin/profile')) {
                $this->callController('AdminController', 'getProfile');
            } elseif ($this->matchRoute('GET', 'admin/statistics')) {
                $this->callController('AdminController', 'getSystemStatistics');
            } elseif ($this->matchRoute('GET', 'admin/users')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('AdminController', 'getUsers', [$page, $limit]);
            } elseif ($this->matchRoute('POST', 'admin/users')) {
                $this->callController('AdminController', 'createUser');
            } elseif ($this->matchRoute('POST', 'admin/users/{userId}/deactivate')) {
                $this->callController('AdminController', 'deactivateUser', ['userId']);
            } elseif ($this->matchRoute('POST', 'admin/users/{userId}/activate')) {
                $this->callController('AdminController', 'activateUser', ['userId']);
            } elseif ($this->matchRoute('GET', 'admin/logs')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? 50;
                $this->callController('AdminController', 'getSystemLogs', [$page, $limit]);
            } elseif ($this->matchRoute('GET', 'admin/activities')) {
                $page = $_GET['page'] ?? 1;
                $limit = $_GET['limit'] ?? DEFAULT_PAGE_SIZE;
                $this->callController('AdminController', 'getUserActivities', [$page, $limit]);
            }

            // Route statut
            elseif ($this->matchRoute('GET', 'health')) {
                Response::success(['status' => 'API en ligne', 'timestamp' => date('Y-m-d H:i:s')], 'API saine');
            }

            // 404
            else {
                Response::notFound('Endpoint non trouvé: ' . $this->method . ' /' . $this->path);
            }

        } catch (Exception $e) {
            error_log('Router Error: ' . $e->getMessage());
            Response::error('Erreur du routeur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }

    /**
     * Vérifier si la route correspond
     */
    private function matchRoute($method, $pattern) {
        if ($this->method !== $method) {
            return false;
        }

        $pathSegments = explode('/', $this->path);
        $patternSegments = explode('/', $pattern);

        if (count($pathSegments) !== count($patternSegments)) {
            return false;
        }

        $this->params = [];
        for ($i = 0; $i < count($patternSegments); $i++) {
            if (preg_match('/^\{(\w+)\}$/', $patternSegments[$i], $matches)) {
                $this->params[$matches[1]] = $pathSegments[$i];
            } elseif ($patternSegments[$i] !== $pathSegments[$i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Appeler un contrôleur
     */
    private function callController($controllerName, $actionName, $args = []) {
        try {
            require_once __DIR__ . '/../controllers/' . $controllerName . '.php';
            
            $controller = new $controllerName();
            
            // Remplacer les placeholders dans les arguments
            $finalArgs = [];
            foreach ($args as $arg) {
                if (is_string($arg) && isset($this->params[$arg])) {
                    $finalArgs[] = $this->params[$arg];
                } else {
                    $finalArgs[] = $arg;
                }
            }

            call_user_func_array([$controller, $actionName], $finalArgs);
        } catch (Exception $e) {
            error_log('Controller Call Error: ' . $e->getMessage());
            Response::error('Erreur lors de l\'appel du contrôleur: ' . $e->getMessage(), HTTP_SERVER_ERROR);
        }
    }
}
?>
