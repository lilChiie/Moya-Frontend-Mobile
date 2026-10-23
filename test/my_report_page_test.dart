import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moya_mobile/core/services/report_service.dart';
import 'package:moya_mobile/features/report/my_report_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'access_token': 'test-token',
      'user_id': 7,
    }),
  );

  test('dirty history excludes reports belonging to other users', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['user_id'], '7');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {'id': 1, 'user_id': 7},
            {'id': 2, 'user_id': 8},
            {'id': 3, 'user_id': '7'},
            {'id': 4},
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);
    final result = await ReportService(client: client).getMyReports();
    expect(result['success'], true);
    expect((result['data'] as List).map((item) => item['id']), [1, 3]);
  });

  testWidgets('tabs show the correct histories and preserve review status', (
    tester,
  ) async {
    await http.runWithClient(
      () async {
        await tester.pumpWidget(const MaterialApp(home: MyReportPage()));
        await tester.pumpAndSettle();
        expect(find.text('My Report'), findsOneWidget);
        expect(find.text('Dirty Reports'), findsOneWidget);
        expect(find.text('Clean Reports'), findsOneWidget);
        expect(find.text('Dirty report note'), findsOneWidget);
        expect(find.text('Other user note'), findsNothing);
        expect(find.text('Beach'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Dirty report note'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Report ID: 1'), findsOneWidget);
        await tester.ensureVisible(find.text('Close'));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Clean Reports'));
        await tester.pumpAndSettle();
        expect(find.text('Clean report note'), findsOneWidget);
        expect(find.text('Verified'), findsOneWidget);
        expect(find.text('Thanks for helping'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Clean report note'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Report ID: 1'), findsOneWidget);
        expect(find.text('Admin Notes:'), findsNothing);
        expect(find.descendant(of: find.byType(Dialog), matching: find.text('Thanks for helping')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Close'));
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(find.text('Clean report note'), findsOneWidget);
      },
      () => MockClient((request) async {
        if (request.url.path == '/api/destinations/') {
          return http.Response(
            '{"success":true,"data":[{"id":3,"name":"Beach"}]}',
            200,
          );
        }
        final clean = request.url.path == '/api/clean-reports/my';
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'user_id': 7,
                'destination_id': 3,
                'notes': clean ? 'Clean report note' : 'Dirty report note',
                'status': clean ? 'verified' : 'pending',
                'created_at': '2026-10-23T12:00:00',
                if (clean) 'admin_notes': 'Thanks for helping',
              },
              if (!clean) {'id': 2, 'user_id': 8, 'notes': 'Other user note'},
            ],
          }),
          200,
        );
      }),
    );
  });
}
