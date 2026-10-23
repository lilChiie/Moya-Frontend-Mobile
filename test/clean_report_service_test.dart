import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moya_mobile/core/services/clean_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  test('unsupported formats and empty photos do not reach server', () async {
    final client = MockClient((_) async {
      fail('Invalid photo must not reach the server.');
    });
    addTearDown(client.close);
    final service = CleanReportService(client: client);
    final unsupported = await service.submit(
      destinationId: 7,
      reportId: 42,
      notes: '',
      image: Uint8List.fromList([1]),
      filename: 'proof.heic',
    );
    expect(unsupported['success'], false);
    expect(unsupported['message'], contains('JPG'));
    final empty = await service.submit(
      destinationId: 7,
      reportId: 42,
      notes: '',
      image: Uint8List(0),
      filename: 'proof.jpg',
    );
    expect(empty['success'], false);
    expect(empty['message'], contains('choose another photo'));
  });

  test('stalled upload stops waiting and suggests checking history', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    addTearDown(client.close);
    final result = await CleanReportService(
      client: client,
      uploadTimeout: const Duration(milliseconds: 20),
    ).submit(
      destinationId: 7,
      reportId: 42,
      notes: '',
      image: Uint8List.fromList([1]),
      filename: 'proof.jpg',
    );
    expect(result['success'], false);
    expect(result['message'], contains('Check My Report'));
  });

  test('stalled response body also stops waiting', () async {
    final body = StreamController<List<int>>();
    final client = _StalledBodyClient(body.stream);
    addTearDown(client.close);
    final result = await CleanReportService(
      client: client,
      uploadTimeout: const Duration(milliseconds: 20),
    ).submit(
      destinationId: 7,
      reportId: 42,
      notes: '',
      image: Uint8List.fromList([1]),
      filename: 'proof.jpg',
    );
    expect(result['success'], false);
    expect(result['message'], contains('Check My Report'));
    await body.close();
  });

  test('uploads evidence using authenticated multipart form', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/clean-reports');
      expect(request.headers['Authorization'], 'Bearer test-token');
      expect(
        request.headers['Content-Type'],
        startsWith('multipart/form-data;'),
      );
      final body = utf8.decode(request.bodyBytes);
      expect(body, contains('name="destination_id"\r\n\r\n7'));
      expect(body, contains('name="report_id"\r\n\r\n42'));
      expect(body, contains('name="notes"\r\n\r\nClean today'));
      expect(body, isNot(contains('name="user_notes"')));
      expect(body, contains('name="image_url"; filename="proof.jpg"'));
      expect(body, contains('content-type: image/jpeg'));
      return http.Response('{"success":true,"message":"Received"}', 201);
    });
    addTearDown(client.close);
    final result = await CleanReportService(client: client).submit(
      destinationId: 7,
      reportId: 42,
      notes: 'Clean today',
      image: Uint8List.fromList([1, 2, 3]),
      filename: 'proof.jpg',
    );
    expect(result['success'], true);
  });

  test('history retains server verification statuses', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/clean-reports/my');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'data': [
            {'id': 1, 'status': 'pending'},
            {'id': 2, 'status': 'verified'},
            {'id': 3, 'status': 'rejected'},
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);
    final result = await CleanReportService(client: client).getMyReports();
    expect(result['success'], true);
    expect((result['data'] as List).map((r) => r['status']), [
      'pending',
      'verified',
      'rejected',
    ]);
  });

  test(
    'expired sessions and HTML errors do not become empty history',
    () async {
      for (final response in [
        http.Response('{"msg":"Token has expired"}', 401),
        http.Response('<html>Gateway error</html>', 502),
        http.Response('{"unexpected":[]}', 200),
      ]) {
        final client = MockClient((_) async => response);
        final result = await CleanReportService(client: client).getMyReports();
        expect(result['success'], false);
        expect(result['message'], isNotEmpty);
        client.close();
      }
    },
  );

  test('missing token prevents uploading', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((_) async {
      fail('An unauthenticated upload must not reach the server.');
    });
    addTearDown(client.close);
    final result = await CleanReportService(client: client).submit(
      destinationId: 7,
      reportId: 42,
      notes: '',
      image: Uint8List.fromList([1]),
      filename: 'proof.jpg',
    );
    expect(result['success'], false);
  });
}

class _StalledBodyClient extends http.BaseClient {
  _StalledBodyClient(this.body);
  final Stream<List<int>> body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(body, 200);
  }
}
