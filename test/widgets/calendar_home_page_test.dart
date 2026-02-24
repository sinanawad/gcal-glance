import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/screens/calendar_home_page.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockGoogleCalendarService extends Mock
    implements GoogleCalendarService {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockGoogleCalendarService mockService;
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue((String _) {});
    registerFallbackValue(MockHttpClient());
  });

  setUp(() {
    mockService = MockGoogleCalendarService();
    mockClient = MockHttpClient();
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
    when(() => mockService.signIn(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    verify(() => mockService.signIn(any())).called(1);
  });

  testWidgets('shows loading spinner before first event load', (tester) async {
    // Auth succeeds, but fetchEvents hangs (never completes).
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) => Completer<List<calendar.Event>>().future);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    // Let auth complete but not fetchEvents.
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state after first load returns no events',
      (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) async => <calendar.Event>[]);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
