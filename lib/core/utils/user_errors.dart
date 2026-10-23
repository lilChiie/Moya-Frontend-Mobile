import 'dart:async';
import 'package:http/http.dart' as http;

class UserErrors {
  static const unavailable =
      'We couldn’t load this right now. Please try again in a moment.';
  static const connection =
      'We couldn’t connect. Check your internet connection and try again.';
  static const timeout = 'This is taking longer than usual. Please try again.';
  static const session = 'Please log in again to continue.';

  static String forStatus(int status, {bool login = false}) {
    if (status == 401) {
      return login
          ? 'Your email or password doesn’t match. Please try again.'
          : session;
    }
    if (status == 403) return 'You don’t have access to this feature.';
    if (status == 413) {
      return 'This photo is too large. Please choose a smaller photo.';
    }
    if (status == 429) return 'Please wait a moment before trying again.';
    if (status == 400 || status == 422) {
      return 'Please check your details and try again.';
    }
    return unavailable;
  }

  static String fromError(Object error) {
    if (error is TimeoutException) return timeout;
    if (error is http.ClientException) return connection;
    return message(error.toString());
  }

  static String message(String? value) {
    if (value == null) return unavailable;
    final safe = [
      unavailable,
      connection,
      timeout,
      session,
      forStatus(401, login: true),
      forStatus(403),
      forStatus(413),
      forStatus(429),
      forStatus(400),
    ];
    if (safe.contains(value)) return value;
    final text = value.toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup')) {
      return connection;
    }
    if (text.contains('timeoutexception')) return timeout;
    if (text.contains('token') || text.contains('log in again')) return session;
    if (text.contains('email') &&
        (text.contains('already') || text.contains('registered'))) {
      return 'This email is already registered. Please log in or use another email.';
    }
    return unavailable;
  }
}
