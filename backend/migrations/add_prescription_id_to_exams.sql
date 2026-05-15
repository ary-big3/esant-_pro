-- Migration: Lier les examens aux ordonnances
-- Date: 30 avril 2026
-- Description: Ajoute la colonne prescription_id à la table exams pour tracer les exams prescrits via ordonnances

ALTER TABLE exams ADD COLUMN prescription_id INT NULL AFTER exam_request_number;

-- Ajouter l'index et la clé étrangère
ALTER TABLE exams ADD KEY idx_prescription_id (prescription_id);
ALTER TABLE exams ADD CONSTRAINT fk_exams_prescription 
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE SET NULL;

-- Ajouter colonne pour le statut d'acceptation du labo
ALTER TABLE exams ADD COLUMN lab_acceptance_status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending' AFTER exam_status;
ALTER TABLE exams ADD COLUMN lab_acceptance_notes TEXT AFTER lab_acceptance_status;
ALTER TABLE exams ADD COLUMN accepted_at DATETIME NULL AFTER lab_acceptance_notes;
ALTER TABLE exams ADD COLUMN accepted_by INT NULL AFTER accepted_at;
ALTER TABLE exams ADD CONSTRAINT fk_exams_accepted_by 
  FOREIGN KEY (accepted_by) REFERENCES users(user_id) ON DELETE SET NULL;
