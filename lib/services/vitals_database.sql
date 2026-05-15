-- ============================================
-- TABLE: patient_vitals
-- Description: Enregistrements des constantes vitales par les infirmières
-- ============================================

CREATE TABLE IF NOT EXISTS patient_vitals (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    nurse_id TEXT NOT NULL,
    
    -- Constantes vitales de base
    temperature REAL NOT NULL,                    -- °C
    tension_systolique INTEGER NOT NULL,          -- mmHg
    tension_diastolique INTEGER NOT NULL,         -- mmHg
    frequence_cardiaque INTEGER NOT NULL,         -- bpm
    frequence_respiratoire INTEGER NOT NULL,      -- rpm
    satur_oxygene REAL NOT NULL,                  -- %O2
    
    -- Mesures supplémentaires
    poids REAL,                                   -- kg
    taille REAL,                                  -- cm
    
    -- Observations
    notes TEXT,
    
    -- Timestamps
    recorded_at DATETIME NOT NULL,                -- Heure de la mesure
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME,
    
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (nurse_id) REFERENCES nurses(id) ON DELETE RESTRICT
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_patient_vitals_patient_id 
    ON patient_vitals(patient_id);

CREATE INDEX IF NOT EXISTS idx_patient_vitals_recorded_at 
    ON patient_vitals(recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_patient_vitals_nurse_id 
    ON patient_vitals(nurse_id);

-- ============================================
-- TABLE: nurses (si elle n'existe pas)
-- Description: Profils des infirmières/infirmiers
-- ============================================

CREATE TABLE IF NOT EXISTS nurses (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    telephone TEXT,
    specialite TEXT,                              -- ex: "Urgences", "Soins intensifs"
    licenseNumber TEXT UNIQUE,                    -- Numéro de licence
    isActive BOOLEAN DEFAULT 1,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- TABLE: vitals_alerts (optionnel)
-- Description: Alertes générées par des constantes anormales
-- ============================================

CREATE TABLE IF NOT EXISTS vitals_alerts (
    id TEXT PRIMARY KEY,
    patient_id TEXT NOT NULL,
    vital_id TEXT NOT NULL,
    alert_type TEXT NOT NULL,                     -- ex: "high_tension", "low_oxygen"
    alert_message TEXT,
    is_acknowledged BOOLEAN DEFAULT 0,
    acknowledged_by TEXT,
    acknowledged_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (vital_id) REFERENCES patient_vitals(id) ON DELETE CASCADE,
    FOREIGN KEY (acknowledged_by) REFERENCES nurses(id) ON DELETE SET NULL
);

-- ============================================
-- VUES UTILES
-- ============================================

-- Vue: Dernières constantes vitales par patient
CREATE VIEW IF NOT EXISTS latest_patient_vitals AS
SELECT 
    pv.*,
    p.nom,
    p.prenom,
    p.groupe_sanguin,
    n.prenom as nurse_prenom,
    n.nom as nurse_nom
FROM patient_vitals pv
JOIN patients p ON pv.patient_id = p.id
JOIN nurses n ON pv.nurse_id = n.id
WHERE pv.id IN (
    SELECT id FROM patient_vitals pv2
    WHERE pv2.patient_id = pv.patient_id
    ORDER BY pv2.recorded_at DESC
    LIMIT 1
);

-- Vue: Statistiques des constantes par patient (24 dernières heures)
CREATE VIEW IF NOT EXISTS patient_vitals_24h_stats AS
SELECT 
    pv.patient_id,
    p.nom,
    p.prenom,
    COUNT(*) as total_records,
    AVG(pv.temperature) as avg_temperature,
    AVG(pv.frequence_cardiaque) as avg_heart_rate,
    AVG(pv.tension_systolique) as avg_sys_tension,
    AVG(pv.tension_diastolique) as avg_dia_tension,
    AVG(pv.satur_oxygene) as avg_oxygen,
    MIN(pv.temperature) as min_temperature,
    MAX(pv.temperature) as max_temperature,
    MIN(pv.recorded_at) as first_record_time,
    MAX(pv.recorded_at) as last_record_time
FROM patient_vitals pv
JOIN patients p ON pv.patient_id = p.id
WHERE pv.recorded_at >= datetime('now', '-24 hours')
GROUP BY pv.patient_id;

-- ============================================
-- DONNÉES DE TEST
-- ============================================

-- Insérer une infirmière de test (si la table nurses existe)
INSERT OR IGNORE INTO nurses (id, user_id, email, nom, prenom, telephone, specialite, licenseNumber, isActive)
VALUES (
    'NURSE-001',
    'NURSE-USER-001',
    'infirmiere@hopital.local',
    'Seck',
    'Aïssatou',
    '+221771234567',
    'Soins généraux',
    'LIC-2025-001',
    1
);

-- ============================================
-- TRIGGERS (optionnels pour audit)
-- ============================================

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER IF NOT EXISTS update_vitals_timestamp 
AFTER UPDATE ON patient_vitals
BEGIN
    UPDATE patient_vitals 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
END;

-- ============================================
-- NOTES D'IMPLÉMENTATION
-- ============================================
/*
1. La table patient_vitals enregistre les constantes vitales mesurées par les infirmières
2. Chaque enregistrement est lié à:
   - Un patient via patient_id
   - Une infirmière via nurse_id
3. Les timestamps recorded_at et created_at permettent de tracer:
   - Quand la mesure a été faite (recorded_at)
   - Quand elle a été entrée (created_at)
4. Les modifications sont tracées via updated_at
5. Les vues permettent:
   - Accès rapide aux dernières constantes
   - Calcul de statistiques sur 24h
6. La table vitals_alerts (optionnelle) peut générer des alertes automatiques
*/
