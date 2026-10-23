import '../utils/user_errors.dart';
import 'api_response.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class CleanReportService {
  CleanReportService({
    http.Client? client,
    Duration uploadTimeout = const Duration(seconds: 45),
  }) : _client = client,
       _uploadTimeout = uploadTimeout;

  final http.Client? _client;
  final Duration _uploadTimeout;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.trim().isEmpty) {
      throw Exception('Please log in again.');
    }
    return {
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401) {
      return {'success': false, 'message': UserErrors.session};
    }
    dynamic body;
    try {
      body = decodeApiResponse(response);
    } catch (error) {
      return {'success': false, 'message': UserErrors.fromError(error)};
    }
    if (body is! Map && body is! List) {
      return {'success': false, 'message': UserErrors.unavailable};
    }
    final success =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (body is! Map || body['success'] != false);
    final data =
        body is List
            ? body
            : body is Map
            ? body['data'] ?? body['reports'] ?? body['clean_reports']
            : null;
    return {
      'success': success,
      'data': data,
      'message':
          body is Map
              ? body['message'] ??
                  body['msg'] ??
                  (success
                      ? 'Report received. Awaiting admin verification.'
                      : UserErrors.unavailable)
              : UserErrors.unavailable,
    };
  }

  Future<Map<String, dynamic>> submit({
    required int reportId,
    required int destinationId,
    required String notes,
    required Uint8List image,
    required String filename,
  }) async {
    final extension = filename.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      return {
        'success': false,
        'message': 'Please choose a JPG, PNG, or WEBP photo.',
      };
    }
    if (image.isEmpty) {
      return {
        'success': false,
        'message':
            'This photo couldn’t be opened. Please choose another photo.',
      };
    }
    final client = _client ?? http.Client();
    final timer = Stopwatch()..start();
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cleanReports}'),
      );
      request.headers.addAll(await _headers());
      request.fields.addAll({
        'report_id': reportId.toString(),
        'destination_id': destinationId.toString(),
        'notes': notes,
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_url',
          image,
          filename: filename,
          contentType: _imageContentType(filename),
        ),
      );
      if (kDebugMode) {
        debugPrint('Clean report upload started: ${image.length} bytes');
      }
      // Bound both waiting for response headers and reading the response body.
      // Closing our client in finally also ends an upload that has stalled.
      final response = await (() async {
        final streamed = await client.send(request);
        if (kDebugMode) {
          debugPrint(
            'Clean report response: HTTP ${streamed.statusCode} after ${timer.elapsedMilliseconds} ms',
          );
        }
        return http.Response.fromStream(streamed);
      })().timeout(_uploadTimeout);
      return _decode(response);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
          'Clean report upload timed out after ${timer.elapsedMilliseconds} ms',
        );
      }
      // The server may already have saved the report before the response stalled.
      return {
        'success': false,
        'message':
            'We couldn’t confirm your report was received. Check My Report before trying again.',
      };
    } catch (error) {
      return {'success': false, 'message': UserErrors.fromError(error)};
    } finally {
      if (_client == null) client.close();
    }
  }

  http.MediaType _imageContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    final subtype = switch (extension) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'webp' => 'webp',
      _ => null,
    };
    return subtype == null
        ? http.MediaType('application', 'octet-stream')
        : http.MediaType('image', subtype);
  }

  Future<Map<String, dynamic>> getMyReports() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.myCleanReports}',
      );
      final headers = await _headers();
      final response = await (_client?.get(url, headers: headers) ??
              http.get(url, headers: headers))
          .timeout(const Duration(seconds: 20));
      final result = _decode(response);
      if (result['success'] == true && result['data'] is! List) {
        return {'success': false, 'message': UserErrors.unavailable};
      }
      return result;
    } catch (error) {
      return {'success': false, 'message': UserErrors.fromError(error)};
    }
  }
}
