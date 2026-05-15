-- =====================================================
-- INSERTION DE TOUTES LES SPÉCIALITÉS MÉDICALES
-- E-Santé - Plateforme Nationale de Santé Numérique
-- =====================================================
-- Script pour ajouter toutes les spécialités manquantes
-- Les spécialités existantes ne seront pas dupliquées
-- =====================================================

USE esante_db;

-- Vérifier les spécialités existantes avant insertion
SELECT 'Spécialités avant insertion:' as status;
SELECT COUNT(*) as total FROM specialities;

-- Insérer les spécialités manquantes de manière idempotente
INSERT IGNORE INTO specialities (name, description, is_active) VALUES
('Médecine Générale', 'Médecine générale de base', TRUE),
('Biologie médicale', 'Analyse et biologie médicale', TRUE),
('Biochimie', 'Analyse biochimique', TRUE),
('Hématologie', 'Étude des maladies du sang', TRUE),
('Microbiologie', 'Étude des micro-organismes', TRUE),
('Génétique', 'Étude de la génétique humaine', TRUE),
('Radiologie / Imagerie médicale', 'Radiologie et imagerie médicale', TRUE),
('Cardiologie', 'Spécialité médicale concernant le cœur et les vaisseaux sanguins', TRUE),
('Neurologie', 'Spécialité médicale concernant le système nerveux', TRUE),
('Pneumologie', 'Spécialité médicale concernant les poumons', TRUE),
('Gastro-entérologie', 'Spécialité médicale concernant le système digestif', TRUE),
('Anatomopathologie', 'Examen des tissus et cellules', TRUE),
('Oncologie', 'Étude et traitement des cancers', TRUE),
('Endocrinologie', 'Spécialité médicale concernant les glandes endocrines', TRUE),
('Gynécologie', 'Spécialité médicale concernant la santé féminine', TRUE),
('Obstétrique', 'Spécialité médicale concernant la grossesse et l\'accouchement', TRUE),
('Urologie', 'Spécialité médicale concernant les voies urinaires', TRUE),
('Andrologie', 'Spécialité médicale concernant la santé masculine', TRUE),
('Rhumatologie', 'Spécialité médicale concernant les articulations', TRUE),
('Orthopédie', 'Spécialité médicale concernant l\'appareil locomoteur', TRUE),
('Ophtalmologie', 'Spécialité médicale concernant les yeux', TRUE),
('ORL', 'Spécialité médicale concernant l\'oreille, le nez et la gorge', TRUE),
('Dermatologie', 'Spécialité médicale concernant la peau', TRUE),
('Néphrologie', 'Spécialité médicale concernant les reins', TRUE),
('Infectiologie', 'Spécialité médicale concernant les maladies infectieuses', TRUE),
('Dentaire', 'Soins dentaires et santé bucco-dentaire', TRUE),
('Psychiatrie / Psychologie', 'Psychiatrie et psychologie médicale', TRUE),
('Pédiatrie / Néonatologie', 'Médecine des enfants et des nouveaux-nés', TRUE),
('Rééducation', 'Rééducation et réadaptation fonctionnelle', TRUE),
('Allergologie', 'Spécialité médicale concernant les allergies', TRUE),
('Médecine du travail', 'Médecine du travail et santé au travail', TRUE),
('Santé publique', 'Santé publique et médecine préventive', TRUE),
('Chirurgie Générale', 'Chirurgie générale', TRUE),
('Anesthésiologie', 'Anesthésie et réanimation', TRUE),
('Urgences', 'Médecine d\'urgence', TRUE);

-- Afficher les spécialités après insertion
SELECT 'Spécialités après insertion:' as status;
SELECT COUNT(*) as total FROM specialities;

-- Afficher toutes les spécialités
SELECT speciality_id, name, description, is_active FROM specialities ORDER BY name;
