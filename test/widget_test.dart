import 'package:flutter_test/flutter_test.dart';
import 'package:laugfs_smart_tracker_pro/app/app.dart';

void main() {
  testWidgets('app boots successfully', (tester) async {
    await tester.pumpWidget(const LaugfsSmartTrackerApp());

    expect(find.text('Laugfs Smart Tracker Pro'), findsOneWidget);
    expect(find.text('START TRACKING'), findsOneWidget);
  });
}