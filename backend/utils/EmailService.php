<?php
/**
 * Service d'envoi d'emails
 * E-Santé - Plateforme Nationale de Santé Numérique
 */

class EmailService {
    private $fromEmail;
    private $fromName;

    public function __construct() {
        $this->fromEmail = getenv('MAIL_FROM_EMAIL') ?: 'noreply@esante.sn';
        $this->fromName = getenv('MAIL_FROM_NAME') ?: 'E-Santé';
    }

    /**
     * Envoyer un email de notification de demande de rendez-vous au médecin
     */
    public function sendAppointmentRequestToDoctor($doctorEmail, $doctorName, $patientName, $speciality, $appointmentDate, $appointmentTime) {
        $subject = '📅 Nouvelle demande de rendez-vous - ' . $speciality;
        
        $message = $this->getEmailTemplate('appointment_request_to_doctor', [
            'doctorName' => $doctorName,
            'patientName' => $patientName,
            'speciality' => $speciality,
            'appointmentDate' => $this->formatDate($appointmentDate),
            'appointmentTime' => $appointmentTime,
            'appUrl' => getenv('APP_URL') ?: 'https://esante.sn'
        ]);

        return $this->sendEmail($doctorEmail, $doctorName, $subject, $message);
    }

    /**
     * Envoyer un email de confirmation de rendez-vous au patient
     */
    public function sendAppointmentConfirmationToPatient($patientEmail, $patientName, $doctorName, $speciality, $appointmentDate, $appointmentTime) {
        $subject = '✅ Rendez-vous confirmé avec Dr. ' . $doctorName;
        
        $message = $this->getEmailTemplate('appointment_confirmation_to_patient', [
            'patientName' => $patientName,
            'doctorName' => $doctorName,
            'speciality' => $speciality,
            'appointmentDate' => $this->formatDate($appointmentDate),
            'appointmentTime' => $appointmentTime,
            'appUrl' => getenv('APP_URL') ?: 'https://esante.sn'
        ]);

        return $this->sendEmail($patientEmail, $patientName, $subject, $message);
    }

    /**
     * Envoyer un email de notification d'envoi de rendez-vous au patient (par médecin)
     */
    public function sendAppointmentScheduledByDoctor($patientEmail, $patientName, $doctorName, $speciality, $appointmentDate, $appointmentTime) {
        $subject = '📋 Dr. ' . $doctorName . ' vous a programmé un rendez-vous';
        
        $message = $this->getEmailTemplate('appointment_scheduled_by_doctor', [
            'patientName' => $patientName,
            'doctorName' => $doctorName,
            'speciality' => $speciality,
            'appointmentDate' => $this->formatDate($appointmentDate),
            'appointmentTime' => $appointmentTime,
            'appUrl' => getenv('APP_URL') ?: 'https://esante.sn'
        ]);

        return $this->sendEmail($patientEmail, $patientName, $subject, $message);
    }

    /**
     * Fonction générique pour envoyer un email
     */
    private function sendEmail($toEmail, $toName, $subject, $message) {
        if (empty($toEmail)) {
            error_log('[EmailService] Email vide pour: ' . $toName);
            return false;
        }

        $headers = "MIME-Version: 1.0" . "\r\n";
        $headers .= "Content-type: text/html; charset=UTF-8" . "\r\n";
        $headers .= "From: " . $this->fromName . " <" . $this->fromEmail . ">" . "\r\n";
        $headers .= "Reply-To: " . $this->fromEmail . "\r\n";

        try {
            $result = mail($toEmail, $subject, $message, $headers);
            
            if ($result) {
                error_log('[EmailService] Email envoyé avec succès à ' . $toEmail);
            } else {
                error_log('[EmailService] Échec de l\'envoi de l\'email à ' . $toEmail);
            }
            
            return $result;
        } catch (Exception $e) {
            error_log('[EmailService] Erreur lors de l\'envoi: ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Récupérer un template d'email
     */
    private function getEmailTemplate($templateName, $variables) {
        $templates = [
            'appointment_request_to_doctor' => $this->templateAppointmentRequestToDoctor($variables),
            'appointment_confirmation_to_patient' => $this->templateAppointmentConfirmationToPatient($variables),
            'appointment_scheduled_by_doctor' => $this->templateAppointmentScheduledByDoctor($variables),
        ];

        return $templates[$templateName] ?? '';
    }

    /**
     * Template : Demande de rendez-vous pour le médecin
     */
    private function templateAppointmentRequestToDoctor($vars) {
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0F1A2E 0%, #14B8A6 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
        .footer { background: #f0f0f0; padding: 10px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 8px 8px; }
        .button { display: inline-block; background: #14B8A6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px; }
        .info-box { background: #e8f4f8; padding: 15px; border-left: 4px solid #14B8A6; margin: 15px 0; }
        strong { color: #0F1A2E; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Nouvelle Demande de Rendez-vous</h1>
        </div>
        <div class="content">
            <p>Bonjour <strong>{$vars['doctorName']}</strong>,</p>
            
            <p>Un patient demande un rendez-vous avec vous en <strong>{$vars['speciality']}</strong>.</p>
            
            <div class="info-box">
                <strong>Détails de la demande :</strong><br>
                Patient : {$vars['patientName']}<br>
                Date demandée : {$vars['appointmentDate']}<br>
                Heure demandée : {$vars['appointmentTime']}<br>
            </div>
            
            <p>Veuillez consulter votre agenda pour accepter ou refuser cette demande.</p>
            
            <a href="{$vars['appUrl']}/doctor/agenda" class="button">Consulter mon agenda</a>
            
            <br><br>
            <p>Cordialement,<br>L'équipe E-Santé</p>
        </div>
        <div class="footer">
            <p>© 2026 E-Santé - Plateforme Nationale de Santé Numérique</p>
        </div>
    </div>
</body>
</html>
HTML;
    }

    /**
     * Template : Confirmation de rendez-vous pour le patient
     */
    private function templateAppointmentConfirmationToPatient($vars) {
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0F1A2E 0%, #14B8A6 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
        .footer { background: #f0f0f0; padding: 10px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 8px 8px; }
        .button { display: inline-block; background: #14B8A6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px; }
        .info-box { background: #e8f8f0; padding: 15px; border-left: 4px solid #10b981; margin: 15px 0; }
        strong { color: #0F1A2E; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✅ Rendez-vous Confirmé</h1>
        </div>
        <div class="content">
            <p>Bonjour <strong>{$vars['patientName']}</strong>,</p>
            
            <p>Votre rendez-vous avec <strong>Dr. {$vars['doctorName']}</strong> a été confirmé !</p>
            
            <div class="info-box">
                <strong>Détails de votre rendez-vous :</strong><br>
                Médecin : Dr. {$vars['doctorName']}<br>
                Spécialité : {$vars['speciality']}<br>
                Date : {$vars['appointmentDate']}<br>
                Heure : {$vars['appointmentTime']}<br>
            </div>
            
            <p>N'oubliez pas d'arriver quelques minutes en avance. En cas d'empêchement, veuillez prévenir dès que possible.</p>
            
            <a href="{$vars['appUrl']}/patient/rdv" class="button">Voir mes rendez-vous</a>
            
            <br><br>
            <p>Cordialement,<br>L'équipe E-Santé</p>
        </div>
        <div class="footer">
            <p>© 2026 E-Santé - Plateforme Nationale de Santé Numérique</p>
        </div>
    </div>
</body>
</html>
HTML;
    }

    /**
     * Template : Rendez-vous programmé par le médecin
     */
    private function templateAppointmentScheduledByDoctor($vars) {
        return <<<HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0F1A2E 0%, #14B8A6 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 20px; border: 1px solid #ddd; }
        .footer { background: #f0f0f0; padding: 10px; text-align: center; font-size: 12px; color: #666; border-radius: 0 0 8px 8px; }
        .button { display: inline-block; background: #14B8A6; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 10px; }
        .info-box { background: #e8f4f8; padding: 15px; border-left: 4px solid #14B8A6; margin: 15px 0; }
        strong { color: #0F1A2E; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 Rendez-vous Programmé</h1>
        </div>
        <div class="content">
            <p>Bonjour <strong>{$vars['patientName']}</strong>,</p>
            
            <p><strong>Dr. {$vars['doctorName']}</strong> vous a programmé un rendez-vous.</p>
            
            <div class="info-box">
                <strong>Détails du rendez-vous :</strong><br>
                Médecin : Dr. {$vars['doctorName']}<br>
                Spécialité : {$vars['speciality']}<br>
                Date : {$vars['appointmentDate']}<br>
                Heure : {$vars['appointmentTime']}<br>
            </div>
            
            <p>Nous vous recommandons de consulter votre dossier médical avant le rendez-vous.</p>
            
            <a href="{$vars['appUrl']}/patient/rdv" class="button">Consulter mon rendez-vous</a>
            
            <br><br>
            <p>Cordialement,<br>L'équipe E-Santé</p>
        </div>
        <div class="footer">
            <p>© 2026 E-Santé - Plateforme Nationale de Santé Numérique</p>
        </div>
    </div>
</body>
</html>
HTML;
    }

    /**
     * Formater une date
     */
    private function formatDate($dateStr) {
        try {
            $date = new DateTime($dateStr);
            $months = [
                1 => 'janvier', 2 => 'février', 3 => 'mars', 4 => 'avril',
                5 => 'mai', 6 => 'juin', 7 => 'juillet', 8 => 'août',
                9 => 'septembre', 10 => 'octobre', 11 => 'novembre', 12 => 'décembre'
            ];
            $days = [
                'Monday' => 'Lundi', 'Tuesday' => 'Mardi', 'Wednesday' => 'Mercredi',
                'Thursday' => 'Jeudi', 'Friday' => 'Vendredi', 'Saturday' => 'Samedi',
                'Sunday' => 'Dimanche'
            ];
            
            $dayName = $days[$date->format('l')] ?? $date->format('l');
            $monthName = $months[(int)$date->format('m')] ?? $date->format('F');
            
            return $dayName . ' ' . $date->format('d') . ' ' . $monthName . ' ' . $date->format('Y');
        } catch (Exception $e) {
            return $dateStr;
        }
    }
}
?>
