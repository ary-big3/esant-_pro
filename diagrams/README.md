# 📊 PlantUML Sequence Diagrams - E-Santé Application

Complete set of sequence diagrams showing all flows in the E-Santé healthcare application.

## 📋 Diagrams Available

### 1. 🔐 Authentication (`1_authentication.puml`)
- User login flow
- Email/password validation
- JWT token generation and storage
- Route to home screen

### 2. 👤 Patient - Medical Dossier (`2_patient_dossier.puml`)
- Patient accesses complete medical file
- 7 tabs: Resume, Consultations, Exams, Diagnostics, Prescriptions, Vaccinations, Documents
- API calls to fetch all data
- Database queries for each section

### 3. 🔍 Doctor - Search Patient (`3_doctor_search.puml`)
- Doctor searches for patient by name/first name/security number
- Search API integration
- Patient list display
- Selection to open patient file

### 4. 📝 Doctor - Create Consultation (`4_doctor_consultation.puml`)
- Doctor views patient dossier
- Creates consultation with diagnosis
- Prescribes exams
- Prescribes medications (ordonnances)
- All data visible to patient immediately

### 5. ⚕️ Nurse - Patients & Vitals (`5_nurse_vitals.puml`)
- Nurse views assigned patients
- Accesses vital signs
- Views consultations and prescriptions
- Can record new measurements

### 6. 🧪 Laboratory - Exam Results (`6_laboratory_results.puml`)
- Lab staff views pending exams
- Enters exam results and observations
- Validates and submits
- Patient receives notification
- Results visible in patient dossier

### 7. 🔑 Patient - Access Control (`7_access_control.puml`)
- Patient views access requests from healthcare providers
- Approves or rejects doctor/nurse/lab access
- Permissions updated in database
- Patient maintains data privacy

### 8. 👨‍💼 Admin - Dashboard (`8_admin_dashboard.puml`)
- Administrator views statistics
- Manages users and roles
- Updates user permissions
- Generates system reports

### 9. 🏗️ System Architecture (`9_architecture.puml`)
- Complete system architecture diagram
- Shows all components and their relationships
- Frontend → Services → Backend → Database flow
- Communication between layers

## 🚀 How to View

### Option 1: VS Code Extension
1. Install "PlantUML" extension (by jebbs)
2. Right-click on any `.puml` file
3. Select "Preview Diagram"

### Option 2: Online Viewer
1. Visit: https://www.plantuml.com/plantuml/uml/
2. Copy-paste diagram content
3. View rendered diagram

### Option 3: Generate SVG/PNG
```bash
java -jar plantuml.jar diagrams/*.puml
```

## 📊 Data Flow Summary

```
USER INPUT
    ↓
FLUTTER WIDGET
    ↓
SERVICE CLASS (AuthService, PatientService, etc.)
    ↓
ApiService (HTTP calls with Bearer Token)
    ↓
BACKEND CONTROLLER (PHP)
    ↓
DATABASE QUERY (MySQL)
    ↓
JSON RESPONSE
    ↓
FLUTTER DISPLAY
```

## 🔗 API Endpoints Used

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration

### Patient
- `GET /medical-dossier/{id}` - Patient dossier (consultations, exams, prescriptions)
- `GET /patient/vitals` - Vital signs
- `GET /patient/prescriptions` - Medications

### Doctor
- `GET /patients/search?q={query}` - Search patients
- `POST /consultations` - Create consultation
- `POST /exams/prescribe` - Prescribe exam
- `POST /prescribe-ordonnance` - Prescribe medication

### Nurse
- `GET /nurse/patients` - Assigned patients
- `GET /patient/{id}/vitals` - Patient vital signs

### Laboratory
- `GET /lab/exams/pending` - Pending exams
- `PUT /exams/{id}/results` - Submit exam results

### Admin
- `GET /admin/statistics` - System statistics
- `GET /admin/users` - All users
- `PUT /admin/users/{id}/role` - Update user role

## 📁 File Structure

```
diagrams/
├── 1_authentication.puml
├── 2_patient_dossier.puml
├── 3_doctor_search.puml
├── 4_doctor_consultation.puml
├── 5_nurse_vitals.puml
├── 6_laboratory_results.puml
├── 7_access_control.puml
├── 8_admin_dashboard.puml
├── 9_architecture.puml
└── README.md (this file)
```

## 🎯 Key Features Visualized

✅ **Multi-role system**: Patient, Doctor, Nurse, Lab, Admin
✅ **Complete patient dossier**: Medical history, exams, prescriptions
✅ **Real-time data sync**: Changes visible immediately to all users
✅ **Access control**: Patient controls who sees their data
✅ **Notifications**: Users alerted to important events
✅ **JWT authentication**: Secure API communication
✅ **Comprehensive API**: 50+ endpoints documented

## 📝 Notes

- All diagrams use actual API endpoints from the backend
- Database tables match the MySQL schema
- Services are Dart classes (ChangeNotifiers)
- API calls include Bearer token authentication
- Responses are JSON format

Generated: May 2026
Version: 1.0
