import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/screens/calendar_home_page.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleCalendarService extends Mock implements GoogleCalendarService {}

void main() {
  late MockGoogleCalendarService mockService;

  setUp(() {
    mockService = MockGoogleCalendarService();
  });

  testWidgets('shows sign-in button when not authenticated', (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('calls signIn when sign-in button is tapped', (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => null);
    when(() => mockService.signIn()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    verify(() => mockService.signIn()).called(1);
  });
}
