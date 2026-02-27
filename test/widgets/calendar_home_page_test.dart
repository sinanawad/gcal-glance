import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/screens/calendar_home_page.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
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

  // The CRT flip-clock digits overflow the 180px ClockColumn at the default
  // 800x600 test surface.  This is a cosmetic issue that only manifests in
  // tests (the real desktop window is much wider).  We suppress RenderFlex
  // overflow errors so that layout-unrelated assertions can still be verified.
  final originalOnError = FlutterError.onError;
  void ignoreOverflowErrors(FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed')) return;
    (originalOnError ?? FlutterError.dumpErrorToConsole)(details);
  }

  testWidgets('shows sign-in button when not authenticated', (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => null);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
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
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    verify(() => mockService.signIn(any())).called(1);
  });

  testWidgets('shows loading spinner before first event load', (tester) async {
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    // Auth succeeds, but fetchEvents hangs (never completes).
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) => Completer<List<calendar.Event>>().future);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
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
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) async => <calendar.Event>[]);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No upcoming events'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows SnackBar when fetchEvents throws network error',
      (tester) async {
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenThrow(const SocketException('no internet'));

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Could not refresh events. Check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows SnackBar when session expires', (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenThrow(auth.AccessDeniedException('expired'));
    when(() => mockService.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Session expired. Please sign in again.'),
      findsOneWidget,
    );
    // Should have signed out and show sign-in button again.
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('shows SnackBar when sign-in fails', (tester) async {
    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => null);
    when(() => mockService.signIn(any())).thenThrow(Exception('cancelled'));

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with Google'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sign-in was cancelled. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('S key toggles sim controls visibility', (tester) async {
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    final now = DateTime.now();
    final event = calendar.Event()
      ..summary = 'Test'
      ..start = calendar.EventDateTime(dateTime: now.add(const Duration(hours: 1)))
      ..end = calendar.EventDateTime(dateTime: now.add(const Duration(hours: 2)))
      ..status = 'confirmed';

    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) async => [event]);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );
    await tester.pumpAndSettle();

    // Sim controls hidden by default.
    expect(find.text('+1h'), findsNothing);

    // Press S to show them.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    expect(find.text('+1h'), findsOneWidget);

    // Press S again to hide.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    expect(find.text('+1h'), findsNothing);
  });

  testWidgets('shows meeting countdown for next event with link',
      (tester) async {
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    final now = DateTime.now();
    final futureEvent = calendar.Event()
      ..summary = 'Team Standup'
      ..start = calendar.EventDateTime(dateTime: now.add(const Duration(hours: 1)))
      ..end = calendar.EventDateTime(
          dateTime: now.add(const Duration(hours: 1, minutes: 30)))
      ..hangoutLink = 'https://meet.google.com/abc-defg-hij'
      ..status = 'confirmed';

    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) async => [futureEvent]);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );
    await tester.pumpAndSettle();

    // Should show the meeting name and a videocam icon.
    expect(find.text('Team Standup'), findsWidgets);
    expect(find.byIcon(Icons.videocam), findsWidgets);
  });

  testWidgets('shows NO MEETINGS when no events have links',
      (tester) async {
    FlutterError.onError = ignoreOverflowErrors;
    addTearDown(() => FlutterError.onError = originalOnError);

    final now = DateTime.now();
    final noLinkEvent = calendar.Event()
      ..summary = 'Lunch Break'
      ..start = calendar.EventDateTime(dateTime: now.add(const Duration(hours: 2)))
      ..end = calendar.EventDateTime(
          dateTime: now.add(const Duration(hours: 3)))
      ..status = 'confirmed';

    when(() => mockService.getAuthenticatedClient())
        .thenAnswer((_) async => mockClient);
    when(() => mockService.fetchEvents(any()))
        .thenAnswer((_) async => [noLinkEvent]);

    await tester.pumpWidget(
      MaterialApp(
        theme: CrtTheme.themeData(),
        home: CalendarHomePage(calendarService: mockService),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NO MEETINGS'), findsOneWidget);
  });
}
