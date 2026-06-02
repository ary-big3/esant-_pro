-- =====================================================
-- MIGRATION: SYSTÈME DE PRESCRIPTION PAR SÉLECTION DE MÉDICAMENTS
-- Date: 20 mai 2026
-- =====================================================

-- 1. Corriger la table medication (ajouter clé primaire)
ALTER TABLE `medication` 
MODIFY `medication_id` int(11) NOT NULL AUTO_INCREMENT,
ADD PRIMARY KEY (`medication_id`);

-- 2. Ajouter une clé étrangère dans prescription_medications pour référencer medication
ALTER TABLE `prescription_medications` 
ADD COLUMN `ref_medication_id` INT DEFAULT NULL AFTER `prescription_id`,
ADD FOREIGN KEY (`ref_medication_id`) REFERENCES `medication`(`medication_id`) ON DELETE SET NULL;

-- 3. Créer un index pour les recherches par catégorie
CREATE INDEX idx_medication_category ON medication(category, is_active);
CREATE INDEX idx_medication_active ON medication(is_active);

-- 4. Créer la table prescription_history pour tracker les modifications
CREATE TABLE `prescription_history` (
  `history_id` INT AUTO_INCREMENT PRIMARY KEY,
  `prescription_id` INT NOT NULL,
  `action` ENUM('created', 'modified', 'sent', 'filled', 'expired', 'cancelled') NOT NULL,
  `action_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `performed_by` INT,
  `notes` TEXT,
  FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions`(`prescription_id`) ON DELETE CASCADE,
  FOREIGN KEY (`performed_by`) REFERENCES `users`(`user_id`) ON DELETE SET NULL,
  INDEX idx_prescription_history (prescription_id, action_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- FIN DE LA MIGRATION
-- =====================================================
