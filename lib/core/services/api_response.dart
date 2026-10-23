import 'package:flutter/foundation.dart';
import '../utils/user_errors.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Show safe messages to users and retain request diagnostics in debug logs.
dynamic decodeApiResponse(http.Response response) {
  final status = response.statusCode;
  if (status >= 400) {
    if (kDebugMode) {
      debugPrint(
        'API failure: HTTP $status ${response.request?.url.path ?? "/api"}',
      );
    }
    throw ApiResponseException(
      UserErrors.forStatus(
        status,
        login: response.request?.url.path.endsWith('/auth/login') == true,
      ),
    );
  }
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['success'] == false) {
      data['message'] = UserErrors.message(
        (data['message'] ?? data['msg'])?.toString(),
      );
      data['msg'] = data['message'];
      data['error'] = data['message'];
    }
    return data;
  } on FormatException {
    if (kDebugMode) {
      debugPrint(
        'Non-JSON API response: HTTP $status ${response.request?.url.path ?? "/api"}',
      );
    }
    throw const ApiResponseException(UserErrors.unavailable);
  }
}

class ApiResponseException implements Exception {
  const ApiResponseException(this.message);

  final String message;

  @override
  String toString() => message;
}
