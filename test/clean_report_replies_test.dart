import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moya_mobile/features/report/clean_report_replies.dart';

void main() {
  testWidgets('long threads expand in batches and can collapse', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CleanReportReplies(
              replies: List.generate(
                8,
                (index) => {
                  'id': index,
                  'user_name': 'User $index',
                  'notes': 'Evidence $index',
                  'created_at': '2026-10-23T12:00:00',
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Evidence 0'), findsOneWidget);
    expect(find.text('Evidence 1'), findsNothing);
    await tester.tap(find.text('See more'));
    await tester.pump();
    expect(find.text('Evidence 3'), findsOneWidget);
    expect(find.text('Evidence 4'), findsNothing);
    await tester.ensureVisible(find.text('See more'));
    await tester.tap(find.text('See more'));
    await tester.pump();
    await tester.ensureVisible(find.text('See more'));
    await tester.tap(find.text('See more'));
    await tester.pump();
    expect(find.text('Evidence 7'), findsOneWidget);
    expect(find.text('See more'), findsNothing);
    await tester.ensureVisible(find.text('See less'));
    await tester.tap(find.text('See less'));
    await tester.pumpAndSettle();
    expect(find.text('Evidence 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
