import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:curasync/config/api_config.dart';

class ApiService {
  static Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Auth ───

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? extraFields,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      ...?extraFields,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: _headers(),
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  // ─── Patient Endpoints ───

  static Future<Map<String, dynamic>> getDoctors({
    required String token,
    String? search,
    String? specialty,
    int page = 1,
    int limit = 5,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
    };

    final uri = Uri.parse(ApiConfig.getDoctors).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDoctorById({
    required String token,
    required String doctorId,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.getDoctorById(doctorId)),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPatientProfile({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.patientProfile),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> joinQueue({
    required String token,
    required String doctorId,
    String? reasonForVisit,
  }) async {
    final body = {
      'doctorId': doctorId,
      if (reasonForVisit != null) 'reasonForVisit': reasonForVisit,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.joinQueue),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getQueueStatus({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.queueStatus),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  // ─── Doctor Endpoints ───

  static Future<Map<String, dynamic>> getDoctorQueue({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse(ApiConfig.doctorQueue),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> callNextPatient({
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.nextPatient),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> toggleAcceptingPatients({
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.toggleAccepting),
      headers: _headers(token: token),
    );

    return jsonDecode(response.body);
  }
}
