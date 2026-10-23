import '../utils/user_errors.dart';
import 'dart:convert';
import 'api_response.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final user = responseData['user'];

        // Prevent non-user roles (like admin) from logging in
        if (user != null && user['role'] != 'user') {
          return {
            'success': false,
            'message': 'Access denied: This application is for users only.',
          };
        }

        // Save user data and token to SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          'access_token',
          responseData['access_token'] ?? '',
        );

        if (user != null) {
          await prefs.setInt('user_id', user['id'] ?? 0);
          await prefs.setString('user_name', user['name'] ?? '');
          await prefs.setString('user_email', user['email'] ?? '');
          await prefs.setString('user_role', user['role'] ?? '');
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': UserErrors.message(responseData['message']?.toString()),
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': UserErrors.message(responseData['message']?.toString()),
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.trim().isEmpty) return false;
    // A saved token can belong to the previous server or have expired.
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 || response.statusCode == 422) {
        await logout();
        return false;
      }
    } catch (_) {
      // Keep the saved session when the server is temporarily unreachable.
    }
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }
}
