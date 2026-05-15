-- Vérifier et insérer les spécialités
USE esante_db;

-- Afficher les spécialités existantes
SELECT * FROM specialities;

-- Vérifier le nombre de spécialités
SELECT COUNT(*) as total_specialities FROM specialities;

-- Si vide, insérer les spécialités
INSERT INTO specialities (name, description, is_active)
SELECT 'Cardiologie', 'Spécialité médicale concernant le cœur et les vaisseaux sanguins', TRUE
WHERE NOT EXISTS (SELECT 1 FROM specialities WHERE name = 'Cardiologie')
UNION ALL
SELECT 'Dermatologie', 'Spécialité médicale concernant la peau', TRUE
WHERE NOT EXISTS (SELECT 1 FROM specialities WHERE name = 'Dermatologie')
UNION ALL
SELECT 'Général', 'Médecine générale', TRUE
WHERE NOT EXISTS (SELECT 1 FROM specialities WHERE name = 'Général')
UNION ALL
SELECT 'Neurologie', 'Spécialité médicale concernant le système nerveux', TRUE
WHERE NOT EXISTS (SELECT 1 FROM specialities WHERE name = 'Neurologie')
UNION ALL
SELECT 'Biochimie', 'Analyse biochimique', TRUE
WHERE NOT EXISTS (SELECT 1 FROM specialities WHERE name = 'Biochimie');

-- Afficher les spécialités après insertion
SELECT * FROM specialities;
