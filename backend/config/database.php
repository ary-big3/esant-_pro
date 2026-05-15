<?php
/**
 * Configuration de la base de données
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

define('DB_HOST', 'localhost');
define('DB_PORT', 3306);
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'esante_db');
define('DB_CHARSET', 'utf8mb4');

/**
 * Class Database
 * Gestion de la connexion à la base de données MySQL
 */
class Database {
    private static $instance = null;
    private $conn;

    private function __construct() {
        try {
            $this->conn = new mysqli(
                DB_HOST,
                DB_USER,
                DB_PASS,
                DB_NAME,
                DB_PORT
            );

            if ($this->conn->connect_error) {
                throw new Exception('Erreur de connexion: ' . $this->conn->connect_error);
            }

            $this->conn->set_charset(DB_CHARSET);
            $this->conn->query("SET time_zone='+00:00'");
        } catch (Exception $e) {
            error_log('Database Connection Error: ' . $e->getMessage());
            http_response_code(500);
            exit(json_encode(['error' => 'Erreur de connexion à la base de données']));
        }
    }

    /**
     * Obtenir l'instance singleton de la base de données
     */
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Obtenir la connexion MySQLi
     */
    public function getConnection() {
        return $this->conn;
    }

    /**
     * Exécuter une requête préparée
     */
    public function execute($query, $params = [], $types = '') {
        try {
            $stmt = $this->conn->prepare($query);
            if (!$stmt) {
                throw new Exception('Erreur de préparation: ' . $this->conn->error);
            }

            if (!empty($params) && !empty($types)) {
                $stmt->bind_param($types, ...$params);
            }

            if (!$stmt->execute()) {
                throw new Exception('Erreur d\'exécution: ' . $stmt->error);
            }

            return $stmt;
        } catch (Exception $e) {
            error_log('Query Execution Error: ' . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Fermer la connexion
     */
    public function closeConnection() {
        if ($this->conn) {
            $this->conn->close();
        }
    }
}
?>
