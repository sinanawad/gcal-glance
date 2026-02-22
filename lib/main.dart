import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gcal_glance/screens/calendar_home_page.dart';
import 'package:gcal_glance/services/google_calendar_service.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarService = GoogleCalendarService(
      httpClientFactory: () => http.Client(),
      secureStorage: const FlutterSecureStorage(),
      clientId: auth.ClientId('placeholder', 'placeholder'),
    );

    return MaterialApp(
      title: 'gcal-glance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CalendarHomePage(calendarService: calendarService),
    );
  }
}
