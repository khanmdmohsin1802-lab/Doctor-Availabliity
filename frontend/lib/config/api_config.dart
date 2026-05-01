class ApiConfig {
  // For Android emulator use 10.0.2.2, for iOS simulator use localhost
  // For physical device, use your machine's local IP
  static const String baseUrl = 'http://10.0.2.2:8001/api/v1';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // Patient endpoints
  static const String getDoctors = '$baseUrl/patients/doctors';
  static String getDoctorById(String id) => '$baseUrl/patients/doctors/$id';
  static const String patientProfile = '$baseUrl/patients/profile';
  static const String joinQueue = '$baseUrl/patients/queue/join';
  static const String queueStatus = '$baseUrl/patients/queue/status';

  // Doctor endpoints
  static const String doctorQueue = '$baseUrl/doctors/dashboard/queue';
  static const String nextPatient = '$baseUrl/doctors/queue/next';
  static const String toggleAccepting = '$baseUrl/doctors/status/toggle';

  // Socket.IO
  static const String socketUrl = 'http://10.0.2.2:8001';
}
