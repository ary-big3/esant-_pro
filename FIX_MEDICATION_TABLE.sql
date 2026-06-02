-- ========================================
-- Mise à jour de la table medication
-- Assurer que medication_id est clé primaire
-- ========================================

-- Si medication_id n'a pas d'AUTO_INCREMENT, l'ajouter
ALTER TABLE `medication` 
MODIFY `medication_id` int(11) NOT NULL AUTO_INCREMENT,
ADD PRIMARY KEY (`medication_id`);

-- Vérifier que la table est bien configurée
-- SELECT * FROM medication LIMIT 1;
