<?php
/**
 * Classe de validation des données
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

require_once __DIR__ . '/../config/constants.php';

class Validator {
    private $errors = [];

    /**
     * Valider un email
     */
    public function validateEmail($email, $fieldName = 'email') {
        if (empty($email)) {
            $this->errors[$fieldName] = 'Email requis';
            return false;
        }
        if (!preg_match(EMAIL_REGEX, $email)) {
            $this->errors[$fieldName] = 'Format email invalide';
            return false;
        }
        return true;
    }

    /**
     * Valider un mot de passe
     */
    public function validatePassword($password, $fieldName = 'password') {
        if (empty($password)) {
            $this->errors[$fieldName] = 'Mot de passe requis';
            return false;
        }
        if (strlen($password) < PASSWORD_MIN_LENGTH) {
            $this->errors[$fieldName] = "Mot de passe minimum " . PASSWORD_MIN_LENGTH . " caractères";
            return false;
        }
        return true;
    }

    /**
     * Valider un téléphone
     */
    public function validatePhone($phone, $fieldName = 'phone') {
        if (empty($phone)) {
            return true; // Optionnel
        }
        if (!preg_match(PHONE_REGEX, $phone)) {
            $this->errors[$fieldName] = 'Format téléphone invalide';
            return false;
        }
        return true;
    }

    /**
     * Valider qu'un champ n'est pas vide
     */
    public function validateRequired($value, $fieldName) {
        if (empty($value)) {
            $this->errors[$fieldName] = ucfirst($fieldName) . ' est requis';
            return false;
        }
        return true;
    }

    /**
     * Valider la longueur d'une chaîne
     */
    public function validateLength($value, $min, $max, $fieldName) {
        $length = strlen($value);
        if ($length < $min || $length > $max) {
            $this->errors[$fieldName] = "$fieldName doit être entre $min et $max caractères";
            return false;
        }
        return true;
    }

    /**
     * Valider qu'une valeur existe dans une liste
     */
    public function validateEnum($value, $allowedValues, $fieldName) {
        if (!in_array($value, $allowedValues)) {
            $this->errors[$fieldName] = "Valeur invalide pour $fieldName";
            return false;
        }
        return true;
    }

    /**
     * Valider une date
     */
    public function validateDate($date, $fieldName = 'date') {
        if (empty($date)) {
            return true;
        }
        $d = \DateTime::createFromFormat('Y-m-d', $date);
        if (!$d || $d->format('Y-m-d') !== $date) {
            $this->errors[$fieldName] = 'Format de date invalide (Y-m-d)';
            return false;
        }
        return true;
    }

    /**
     * Valider une date avec heure (Y-m-d H:i:s ou Y-m-d)
     */
    public function validateDateTime($dateTime, $fieldName = 'datetime') {
        if (empty($dateTime)) {
            return true;
        }
        
        // Essayer le format avec heure d'abord
        $d = \DateTime::createFromFormat('Y-m-d H:i:s', $dateTime);
        if ($d && $d->format('Y-m-d H:i:s') === $dateTime) {
            return true;
        }
        
        // Essayer le format date seule
        $d = \DateTime::createFromFormat('Y-m-d', $dateTime);
        if ($d && $d->format('Y-m-d') === $dateTime) {
            return true;
        }
        
        $this->errors[$fieldName] = 'Format de date/heure invalide (Y-m-d ou Y-m-d H:i:s)';
        return false;
    }

    /**
     * Valider qu'une date n'est pas dans le futur
     */
    public function validateNotFuture($date, $fieldName = 'date') {
        if (!$this->validateDate($date, $fieldName)) {
            return false;
        }
        if (strtotime($date) > time()) {
            $this->errors[$fieldName] = $fieldName . ' ne peut pas être dans le futur';
            return false;
        }
        return true;
    }

    /**
     * Valider un groupe sanguin
     */
    public function validateBloodGroup($bloodGroup, $fieldName = 'blood_group') {
        $validGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
        return $this->validateEnum($bloodGroup, $validGroups, $fieldName);
    }

    /**
     * Valider un sexe
     */
    public function validateGender($gender, $fieldName = 'gender') {
        $validGenders = ['M', 'F', 'Autre'];
        return $this->validateEnum($gender, $validGenders, $fieldName);
    }

    /**
     * Obtenir les erreurs
     */
    public function getErrors() {
        return $this->errors;
    }

    /**
     * Vérifier s'il y a des erreurs
     */
    public function hasErrors() {
        return !empty($this->errors);
    }

    /**
     * Nettoyer une chaîne
     */
    public static function sanitize($data) {
        if (is_array($data)) {
            return array_map([self::class, 'sanitize'], $data);
        }
        return trim(strip_tags($data));
    }

    /**
     * Valider une structure JSON
     */
    public static function validateJSON($json) {
        json_decode($json);
        return json_last_error() === JSON_ERROR_NONE;
    }
}
?>
