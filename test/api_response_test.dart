import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:moya_mobile/core/services/api_response.dart';
import 'package:moya_mobile/core/utils/user_errors.dart';

void main() {
  http.Response response(String body, int status) => http.Response(
    body,
    status,
    request: http.Request(
      'GET',
      Uri.parse('https://example.com/api/destinations/'),
    ),
  );

  test('preserves JSON responses', () {
    expect(decodeApiResponse(response('{"data":[]}', 200)), {'data': []});
  });

  test('HTML server errors use a friendly message', () {
    expect(
      () => decodeApiResponse(
        response('<!doctype html><title>Internal Server Error</title>', 500),
      ),
      throwsA(
        isA<ApiResponseException>().having(
          (e) => e.message,
          'message',
          UserErrors.unavailable,
        ),
      ),
    );
  });

  test('ngrok HTML does not expose tunnel details', () {
    expect(
      () => decodeApiResponse(response('<html>ERR_NGROK_3200</html>', 404)),
      throwsA(
        isA<ApiResponseException>().having(
          (e) => e.message,
          'message',
          UserErrors.unavailable,
        ),
      ),
    );
  });

  test('technical backend messages are replaced even on HTTP 200', () {
    final data = decodeApiResponse(
      response(
        '{"success":false,"message":"SQLAlchemy OperationalError at localhost"}',
        200,
      ),
    );
    expect(data['message'], UserErrors.unavailable);
  });

  test('network, timeout and session messages give an action', () {
    expect(
      UserErrors.message('SocketException: host unreachable'),
      UserErrors.connection,
    );
    expect(UserErrors.message('TimeoutException'), UserErrors.timeout);
    expect(UserErrors.forStatus(401), UserErrors.session);
    expect(UserErrors.forStatus(413), contains('smaller photo'));
    expect(
      UserErrors.message('Exception: arbitrary secret error'),
      UserErrors.unavailable,
    );
  });

  test('HTML with HTTP 200 never masquerades as an empty list', () {
    expect(
      () =>
          decodeApiResponse(response('<!doctype html><html>Login</html>', 200)),
      throwsA(isA<ApiResponseException>()),
    );
  });
}
