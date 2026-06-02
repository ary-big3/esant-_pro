-- =====================================================
-- BASE DE DONNÉES E-SANTÉ - SCRIPT DE CRÉATION
-- Date: 14 avril 2026
-- Version: 1.0.0
-- =====================================================

-- Créer la base de données
DROP DATABASE IF EXISTS esante_db;
CREATE DATABASE esante_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE esante_db;

-- =====================================================
-- 1. TABLE USERS (AUTHENTIFICATION & BASE)
-- =====================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role ENUM('patient', 'medecin', 'infirmiere', 'admin', 'laboratoire') NOT NULL DEFAULT 'patient',
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 2. TABLE PATIENTS (GESTION DES PATIENTS)
-- =====================================================
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('M', 'F') NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    postal_code VARCHAR(10),
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    social_security_number VARCHAR(50) UNIQUE,
    parent_id INT,
    is_child BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES patients(patient_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_email (email),
    INDEX idx_parent_id (parent_id),
    INDEX idx_is_child (is_child)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 3. TABLE MEDICAL HISTORY
-- =====================================================
CREATE TABLE medical_history (
    medical_history_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL UNIQUE,
    medical_conditions TEXT,
    family_history TEXT,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    chronic_diseases JSON,
    known_allergies JSON,
    updated_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 4. TABLE ALLERGIES
-- =====================================================
CREATE TABLE allergies (
    allergy_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    allergy_type ENUM('medicament', 'aliment', 'substance', 'autre') NOT NULL,
    allergy_name VARCHAR(255) NOT NULL,
    severity ENUM('doux', 'modere', 'grave', 'critique') NOT NULL,
    reaction_description TEXT,
    documented_date DATE NOT NULL,
    documented_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (documented_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 5. TABLE VACCINATIONS
-- =====================================================
CREATE TABLE vaccinations (
    vaccination_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    vaccine_name VARCHAR(255) NOT NULL,
    vaccine_type VARCHAR(100),
    dose_number INT NOT NULL DEFAULT 1,
    vaccination_date DATE NOT NULL,
    administered_by INT,
    next_dose_date DATE,
    manufacturer VARCHAR(100),
    batch_number VARCHAR(100),
    administration_site VARCHAR(100),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (administered_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_vaccination_date (vaccination_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 6. TABLE VITAL SIGNS
-- =====================================================
CREATE TABLE vital_signs (
    vital_sign_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    nurse_id INT,
    measurement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    temperature_celsius DECIMAL(4, 2),
    systolic_pressure INT,
    diastolic_pressure INT,
    pulse_bpm INT,
    respiratory_rate INT,
    oxygen_saturation DECIMAL(5, 2),
    weight_kg DECIMAL(6, 2),
    height_cm INT,
    bmi DECIMAL(5, 2) GENERATED ALWAYS AS (weight_kg / ((height_cm / 100) * (height_cm / 100))) STORED,
    status ENUM('normal', 'abnormal', 'critical') DEFAULT 'normal',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (nurse_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_measurement_date (measurement_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 7. TABLE MEDICAL DOCUMENTS
-- =====================================================
CREATE TABLE medical_documents (
    document_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    document_type ENUM('prescription', 'examen', 'rapport_medical', 'imagerie', 'analyse', 'autre') NOT NULL,
    document_title VARCHAR(255) NOT NULL,
    document_description TEXT,
    file_path VARCHAR(500) NOT NULL,
    file_size_kb INT,
    file_format VARCHAR(50),
    uploaded_by INT,
    upload_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    document_date DATE,
    related_consultation_id INT,
    related_exam_id INT,
    is_available_for_download BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_document_type (document_type),
    INDEX idx_upload_date (upload_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 8. TABLE HOSPITALS
-- =====================================================
CREATE TABLE hospitals (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(255),
    established_date DATE,
    total_beds INT,
    emergency_contact VARCHAR(20),
    director_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_city (city),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 9. TABLE SPECIALITIES
-- =====================================================
CREATE TABLE specialities (
    speciality_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    laboratory_assignment INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 10. TABLE DOCTORS (GESTION MÉDICALE)
-- =====================================================
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    medical_license VARCHAR(100) UNIQUE NOT NULL,
    medical_license_expiry DATE,
    speciality VARCHAR(255),
    hospital_id INT,
    biography TEXT,
    profile_photo VARCHAR(500),
    consultation_rate DECIMAL(10, 2),
    is_available BOOLEAN DEFAULT TRUE,
    average_rating DECIMAL(3, 2) DEFAULT 0,
    total_consultations INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_hospital_id (hospital_id),
    INDEX idx_is_available (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 11. TABLE NURSES (GESTION MÉDICALE)
-- =====================================================
CREATE TABLE nurses (
    nurse_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    nursing_license VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(100),
    hospital_id INT,
    is_available BOOLEAN DEFAULT TRUE,
    shift_schedule VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_hospital_id (hospital_id),
    INDEX idx_is_available (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 12. TABLE LABORATORIES
-- =====================================================
CREATE TABLE laboratories (
    laboratory_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    postal_code VARCHAR(10),
    responsible_person VARCHAR(255),
    specialities_covered TEXT,
    opening_hours VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_city (city),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 13. TABLE DOCTOR SPECIALITIES
-- =====================================================
CREATE TABLE doctor_specialities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    speciality_id INT NOT NULL,
    years_of_experience INT,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (speciality_id) REFERENCES specialities(speciality_id) ON DELETE CASCADE,
    UNIQUE KEY unique_doctor_speciality (doctor_id, speciality_id),
    INDEX idx_speciality_id (speciality_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 14. TABLE CONSULTATIONS (WORKFLOWS CLINIQUES)
-- =====================================================
CREATE TABLE consultations (
    consultation_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    speciality_id INT,
    consultation_date DATETIME NOT NULL,
    consultation_type ENUM('en_personne', 'teleconsultation', 'suivi') DEFAULT 'en_personne',
    reason_for_visit VARCHAR(255),
    chief_complaint TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    notes TEXT,
    future_date_follow_up DATE,
    consultation_status ENUM('completed', 'pending', 'cancelled') DEFAULT 'pending',
    prescription_included BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (speciality_id) REFERENCES specialities(speciality_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_consultation_date (consultation_date),
    INDEX idx_status (consultation_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 15. TABLE PRESCRIPTIONS
-- =====================================================
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    consultation_id INT NOT NULL,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    prescription_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    prescription_number VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('active', 'expired', 'completed', 'cancelled') DEFAULT 'active',
    issue_date DATE NOT NULL,
    expiry_date DATE,
    notes TEXT,
    can_share BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (consultation_id) REFERENCES consultations(consultation_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_prescription_number (prescription_number),
    INDEX idx_status (status),
    INDEX idx_expiry_date (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 16. TABLE PRESCRIPTION MEDICATIONS
-- =====================================================
CREATE TABLE prescription_medications (
    medication_id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    medication_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    dosage_unit ENUM('mg', 'g', 'ml', 'l', 'mcg', 'mmol', 'autre') NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration VARCHAR(100),
    route_of_administration ENUM('oral', 'injectable', 'topique', 'inhalee', 'rectale', 'autre') DEFAULT 'oral',
    special_instructions TEXT,
    is_essential BOOLEAN DEFAULT FALSE,
    sequence_order INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    INDEX idx_prescription_id (prescription_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 17. TABLE EXAMS
-- =====================================================
CREATE TABLE exams (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    speciality_id INT,
    laboratory_id INT,
    exam_request_number VARCHAR(100) NOT NULL UNIQUE,
    exam_date DATETIME,
    exam_type VARCHAR(255) NOT NULL,
    urgency_level ENUM('normal', 'urgent', 'tres_urgent') DEFAULT 'normal',
    observations TEXT,
    exam_status ENUM('pending', 'in_progress', 'completed', 'cancelled') DEFAULT 'pending',
    result_interpretation ENUM('normal', 'abnormal', 'to_verify') DEFAULT 'to_verify',
    result_values TEXT,
    result_interpretation_notes TEXT,
    signed_by_technician INT,
    signature_date DATETIME,
    notification_patient_sent BOOLEAN DEFAULT FALSE,
    notification_doctor_sent BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (speciality_id) REFERENCES specialities(speciality_id) ON DELETE SET NULL,
    FOREIGN KEY (laboratory_id) REFERENCES laboratories(laboratory_id) ON DELETE SET NULL,
    FOREIGN KEY (signed_by_technician) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_exam_date (exam_date),
    INDEX idx_exam_status (exam_status),
    INDEX idx_urgency_level (urgency_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 18. TABLE EXAM RESULTS
-- =====================================================
CREATE TABLE exam_results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    test_name VARCHAR(255) NOT NULL,
    measured_value DECIMAL(10, 4),
    unit VARCHAR(50),
    reference_min DECIMAL(10, 4),
    reference_max DECIMAL(10, 4),
    is_abnormal BOOLEAN DEFAULT FALSE,
    interpretation VARCHAR(255),
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(exam_id) ON DELETE CASCADE,
    INDEX idx_exam_id (exam_id),
    INDEX idx_is_abnormal (is_abnormal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 18.5 TABLE APPOINTMENT REQUESTS (DEMANDES DE RENDEZ-VOUS)
-- =====================================================
CREATE TABLE appointment_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    speciality_id INT,
    appointment_date DATETIME NOT NULL,
    appointment_duration_minutes INT DEFAULT 30,
    appointment_type ENUM('consultation', 'suivi', 'examen', 'autre') DEFAULT 'consultation',
    reason_for_appointment VARCHAR(255),
    notes TEXT,
    status ENUM('pending', 'accepted', 'cancelled') DEFAULT 'pending',
    accepted_by_doctor_id INT,
    accepted_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (speciality_id) REFERENCES specialities(speciality_id) ON DELETE SET NULL,
    FOREIGN KEY (accepted_by_doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_speciality_id (speciality_id),
    INDEX idx_status (status),
    INDEX idx_appointment_date (appointment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 19. TABLE APPOINTMENTS
-- =====================================================
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    appointment_duration_minutes INT DEFAULT 30,
    speciality_id INT,
    hospital_id INT,
    appointment_type ENUM('consultation', 'suivi', 'examen', 'autre') DEFAULT 'consultation',
    status ENUM('confirmed', 'pending', 'completed', 'cancelled', 'no_show') DEFAULT 'pending',
    reason_for_appointment VARCHAR(255),
    notes TEXT,
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_date DATETIME,
    appointment_request_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (speciality_id) REFERENCES specialities(speciality_id) ON DELETE SET NULL,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) ON DELETE SET NULL,
    FOREIGN KEY (appointment_request_id) REFERENCES appointment_requests(request_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_appointment_date (appointment_date),
    INDEX idx_status (status),
    INDEX idx_request_id (appointment_request_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 20. TABLE MESSAGES (COMMUNICATION)
-- =====================================================
CREATE TABLE messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    recipient_id INT NOT NULL,
    subject VARCHAR(255),
    message_body TEXT NOT NULL,
    message_type ENUM('consultation', 'prescription_follow_up', 'appointment_reminder', 'general') DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    attachment_path VARCHAR(500),
    related_consultation_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (related_consultation_id) REFERENCES consultations(consultation_id) ON DELETE SET NULL,
    INDEX idx_sender_id (sender_id),
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 21. TABLE NOTIFICATIONS
-- =====================================================
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    notification_type ENUM('exam_requested', 'result_ready', 'appointment_reminder', 'appointment_scheduled', 'access_request', 'access_approved', 'access_rejected', 'message', 'alert', 'other') DEFAULT 'other',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_patient_id INT,
    related_exam_id INT,
    related_appointment_id INT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    action_url VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (related_patient_id) REFERENCES patients(patient_id) ON DELETE SET NULL,
    FOREIGN KEY (related_exam_id) REFERENCES exams(exam_id) ON DELETE SET NULL,
    FOREIGN KEY (related_appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 22. TABLE ADMIN USERS (SÉCURITÉ)
-- =====================================================
CREATE TABLE admin_users (
    admin_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    department VARCHAR(100),
    access_level ENUM('super_admin', 'admin', 'moderator') DEFAULT 'admin',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_access_level (access_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 23. TABLE ACCESS PERMISSIONS
-- =====================================================
CREATE TABLE access_permissions (
    permission_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    authorized_user_id INT NOT NULL,
    permission_type ENUM('view_only', 'view_and_download', 'full_access') DEFAULT 'view_only',
    granted_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME,
    granted_by INT,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_date DATETIME,
    revoked_by INT,
    reason TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (authorized_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (granted_by) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (revoked_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_patient_id (patient_id),
    INDEX idx_authorized_user_id (authorized_user_id),
    INDEX idx_is_revoked (is_revoked),
    INDEX idx_expiry_date (expiry_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 23b. TABLE ACCESS REQUESTS (DEMANDES D'ACCÈS)
-- =====================================================
CREATE TABLE access_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    requester_user_id INT NOT NULL,
    reason_for_access TEXT,
    permission_type ENUM('view_only', 'view_and_download', 'full_access') DEFAULT 'view_only',
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    responded_at DATETIME,
    response_reason TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (requester_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_status (status),
    INDEX idx_requested_at (requested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 24. TABLE ACCESS LOGS
-- =====================================================
CREATE TABLE access_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    accessed_patient_id INT,
    action_type ENUM('view', 'download', 'modify', 'delete', 'create') NOT NULL,
    resource_type ENUM('patient_record', 'medical_document', 'prescription', 'exam', 'appointment', 'message') NOT NULL,
    resource_id INT,
    access_status ENUM('success', 'denied', 'failed') DEFAULT 'success',
    ip_address VARCHAR(50),
    user_agent TEXT,
    access_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (accessed_patient_id) REFERENCES patients(patient_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_accessed_patient_id (accessed_patient_id),
    INDEX idx_access_timestamp (access_timestamp),
    INDEX idx_action_type (action_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 25. TABLE SYSTEM SETTINGS
-- =====================================================
CREATE TABLE system_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(255) NOT NULL UNIQUE,
    setting_value LONGTEXT,
    setting_type ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
    setting_category VARCHAR(100),
    description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    updated_by INT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_setting_key (setting_key),
    INDEX idx_setting_category (setting_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 26. TABLE UNAVAILABLE SLOTS (CRÉNEAUX INDISPONIBLES)
-- =====================================================
CREATE TABLE unavailable_slots (
    unavailable_slot_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    reason VARCHAR(255),
    created_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_start_date (start_date),
    INDEX idx_end_date (end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- 27. TABLE DOCTOR-PATIENT REQUESTS (DEMANDES D'ACCÈS)
-- =====================================================
CREATE TABLE doctor_patient_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    patient_id INT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    reason VARCHAR(500),
    requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    responded_at DATETIME,
    responded_by INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (responded_by) REFERENCES users(user_id) ON DELETE SET NULL,
    UNIQUE KEY unique_request (doctor_id, patient_id),
    INDEX idx_patient_id (patient_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_status (status),
    INDEX idx_requested_at (requested_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `medication` (
  `medication_id` int(11) NOT NULL,
  `medication_name` varchar(255) NOT NULL,
  `generic_name` varchar(255) DEFAULT NULL,
  `dosage` varchar(50) NOT NULL,
  `dosage_unit` varchar(20) NOT NULL DEFAULT 'mg',
  `frequency` varchar(50) NOT NULL DEFAULT '1x/jour',
  `default_duration` int(11) NOT NULL DEFAULT 7,
  `route_of_administration` varchar(50) NOT NULL DEFAULT 'oral',
  `category` varchar(100) NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `medication`
--

INSERT INTO `medication` (`medication_id`, `medication_name`, `generic_name`, `dosage`, `dosage_unit`, `frequency`, `default_duration`, `route_of_administration`, `category`, `is_active`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Amoxicilline', 'amoxicilline', '500', 'mg', '3x/jour', 7, 'oral', 'Antibiotique', 1, 'Antibiotique beta-lactamines à large spectre', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(2, 'Amoxicilline-Acide clavulanique', 'amoxicilline/acide clavulanique', '500/125', 'mg', '3x/jour', 7, 'oral', 'Antibiotique', 1, 'Antibiotique avec inhibiteur de bêta-lactamase', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(3, 'Azithromycine', 'azithromycine', '500', 'mg', '1x/jour', 5, 'oral', 'Antibiotique', 1, 'Macrolide pour infections respiratoires', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(4, 'Ciprofloxacine', 'ciprofloxacine', '500', 'mg', '2x/jour', 7, 'oral', 'Antibiotique', 1, 'Fluoroquinolone à large spectre', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(5, 'Ceftriaxone', 'ceftriaxone', '1', 'g', '2x/jour', 7, 'injectable', 'Antibiotique', 1, 'Céphalosporine de 3e génération', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(6, 'Paracétamol', 'paracétamol', '500', 'mg', '3x/jour', 3, 'oral', 'Antalgique', 1, 'Antalgique et antipyrétique', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(7, 'Ibuprofen', 'ibuprofène', '200', 'mg', '3x/jour', 5, 'oral', 'Anti-inflammatoire', 1, 'AINS pour douleurs et inflammations', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(8, 'Diclofenac', 'diclofénac', '50', 'mg', '2x/jour', 5, 'oral', 'Anti-inflammatoire', 1, 'AINS pour douleurs modérées', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(9, 'Acide acétylsalicylique', 'acide acétylsalicylique', '500', 'mg', '2x/jour', 3, 'oral', 'Antalgique', 1, 'Aspirine pour douleurs légères', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(10, 'Cetirizine', 'cétirizine', '10', 'mg', '1x/jour', 7, 'oral', 'Antihistaminique', 1, 'Antihistaminique non-sédatif', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(11, 'Loratadine', 'loratadine', '10', 'mg', '1x/jour', 7, 'oral', 'Antihistaminique', 1, 'Antihistaminique pour rhinite allergique', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(12, 'Dexaméthasone', 'dexaméthasone', '0.5', 'mg', '3x/jour', 5, 'oral', 'Corticostéroïde', 1, 'Corticostéroïde anti-inflammatoire', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(13, 'Métoclopramide', 'métoclopramide', '10', 'mg', '3x/jour', 5, 'oral', 'Anti-nausées', 1, 'Antiémétique et prokinétique', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(14, 'Dompéridone', 'dompéridone', '10', 'mg', '3x/jour', 5, 'oral', 'Anti-nausées', 1, 'Antiémétique pour nausées', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(15, 'Oméprazole', 'oméprazole', '20', 'mg', '1x/jour', 7, 'oral', 'Digestif', 1, 'Inhibiteur de pompe à protons', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(16, 'Ranitidine', 'ranitidine', '150', 'mg', '2x/jour', 7, 'oral', 'Digestif', 1, 'Antagoniste H2 pour ulcères', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(17, 'Codéine', 'codéine', '30', 'mg', '3x/jour', 5, 'oral', 'Antitussif', 1, 'Sirop ou comprimés anti-toux', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(18, 'Ambroxol', 'ambroxol', '30', 'mg', '3x/jour', 7, 'oral', 'Expectorant', 1, 'Mucolytique pour toux productive', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(19, 'Salbutamol', 'salbutamol', '100', 'mcg', 'selon besoin', 7, 'inhalée', 'Bronchodilatateur', 1, 'Inhalateur pour asthme', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(20, 'Acyclovir', 'acyclovir', '400', 'mg', '3x/jour', 7, 'oral', 'Antiviral', 1, 'Antiviral pour herpès', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(21, 'Oseltamivir', 'oseltamivir', '75', 'mg', '2x/jour', 5, 'oral', 'Antiviral', 1, 'Traitement grippe', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(22, 'Metformine', 'metformine', '500', 'mg', '2x/jour', 365, 'oral', 'Antidiabétique', 1, 'Biguanide pour diabète type 2', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(23, 'Glibenclamide', 'glibenclamide', '5', 'mg', '1x/jour', 365, 'oral', 'Antidiabétique', 1, 'Sulfonylurée pour diabète type 2', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(24, 'Lisinopril', 'lisinopril', '10', 'mg', '1x/jour', 365, 'oral', 'Antihypertenseur', 1, 'IEC pour hypertension', '2026-05-12 08:43:34', '2026-05-12 08:43:34'),
(25, 'Aténolol', 'aténolol', '50', 'mg', '1x/jour', 365, 'oral', 'Antihypertenseur', 1, 'Béta-bloquant pour cœur', '2026-05-12 08:43:34', '2026-05-12 08:43:34');

-- --------------------------------------------------------


-- =====================================================
-- INDEXES ADDITIONNELS POUR OPTIMISATION
-- =====================================================

-- Index composite pour les recherches fréquentes
CREATE INDEX idx_patient_consultation ON consultations(patient_id, consultation_date DESC);
CREATE INDEX idx_doctor_consultation ON consultations(doctor_id, consultation_date DESC);
CREATE INDEX idx_patient_exam ON exams(patient_id, exam_date DESC);
CREATE INDEX idx_patient_appointment ON appointments(patient_id, appointment_date DESC);
CREATE INDEX idx_doctor_appointment ON doctors(hospital_id, is_available);
CREATE INDEX idx_nurse_hospital ON nurses(hospital_id, is_available);

-- =====================================================
-- CONTRAINTES DE VÉRIFICATION (CHECK)
-- =====================================================

-- Vérifier que les dates de rendez-vous sont dans le futur
ALTER TABLE appointments ADD CONSTRAINT check_appointment_date 
CHECK (appointment_date > CURRENT_TIMESTAMP);

-- Vérifier que la date de vaccination n'est pas dans le futur
ALTER TABLE vaccinations ADD CONSTRAINT check_vaccination_date 
CHECK (vaccination_date <= CURDATE());

-- Vérifier que le BMI calculé est réaliste (optionnel mais recommandé)
ALTER TABLE vital_signs ADD CONSTRAINT check_bmi_range 
CHECK (bmi > 0 AND bmi < 100);

-- Vérifier que la date de naissance n'est pas dans le futur
ALTER TABLE patients ADD CONSTRAINT check_date_of_birth 
CHECK (date_of_birth < CURDATE());

-- Vérifier que l'expiration de la prescription est après sa création
ALTER TABLE prescriptions ADD CONSTRAINT check_prescription_dates 
CHECK (expiry_date IS NULL OR expiry_date >= issue_date);

-- Vérifier que la date d'expiration des permissions est après la date d'attribution
ALTER TABLE access_permissions ADD CONSTRAINT check_permission_dates 
CHECK (expiry_date IS NULL OR expiry_date >= granted_date);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger : Mettre à jour updated_at de users
DELIMITER //
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//
DELIMITER ;

-- Trigger : Mettre à jour total_consultations du docteur
DELIMITER //
CREATE TRIGGER trg_update_doctor_consultations
AFTER INSERT ON consultations
FOR EACH ROW
BEGIN
    UPDATE doctors SET total_consultations = total_consultations + 1 
    WHERE doctor_id = NEW.doctor_id;
END//
DELIMITER ;

-- Trigger : Vérifier que l'enfant a bien un parent
DELIMITER //
CREATE TRIGGER trg_check_child_parent
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
    IF NEW.is_child = TRUE AND NEW.parent_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Un enfant doit avoir un parent associé';
    END IF;
END//
DELIMITER ;

-- =====================================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insertion test : Créer un utilisateur test
INSERT INTO users (email, password_hash, full_name, phone, role, is_active) 
VALUES 
    ('admin@esante.com', 'hashed_password_admin', 'Admin Système', '+33612345678', 'admin', TRUE),
    ('test_patient@esante.com', 'hashed_password_patient', 'Jean Dupont', '+33698765432', 'patient', TRUE),
    ('test_doctor@esante.com', 'hashed_password_doctor', 'Dr. Marie Martin', '+33687654321', 'medecin', TRUE);

-- Insertion test : Créer un patient test
INSERT INTO patients (user_id, first_name, last_name, date_of_birth, gender, email, phone, blood_group, is_child)
VALUES 
    (2, 'Jean', 'Dupont', '1985-05-15', 'M', 'test_patient@esante.com', '+33698765432', 'O+', FALSE);

-- Insertion test : Créer un hôpital test
INSERT INTO hospitals (name, city, address, postal_code, phone, email, established_date, total_beds, director_name, is_active)
VALUES 
    ('Hôpital Central', 'Paris', '123 Rue de la Paix', '75001', '+33123456789', 'contact@hopital-central.fr', '1995-01-01', 500, 'Dr. Pierre Leclerc', TRUE);

-- Insertion test : Créer une spécialité test
INSERT INTO specialities (name, description, is_active)
VALUES 
    ('Cardiologie', 'Spécialité médicale concernant le cœur et les vaisseaux sanguins', TRUE),
    ('Dermatologie', 'Spécialité médicale concernant la peau', TRUE),
    ('Général', 'Médecine générale', TRUE);

-- Insertion test : Créer un docteur test
INSERT INTO doctors (user_id, first_name, last_name, email, phone, medical_license, hospital_id, speciality, is_available, consultation_rate)
VALUES 
    (3, 'Marie', 'Martin', 'test_doctor@esante.com', '+33687654321', 'DM123456789', 1, 'Cardiologie', TRUE, 50.00);

-- =====================================================
-- FIN DU SCRIPT
-- =====================================================
-- Base de données créée le 14 avril 2026
-- Version: 1.0.0
-- Statut: Prête pour développement
