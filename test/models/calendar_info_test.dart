import 'package:flutter_test/flutter_test.dart';
import 'package:gcal_glance/models/calendar_info.dart';

void main() {
  group('CalendarInfo', () {
    test('constructs with required fields', () {
      final cal = CalendarInfo(id: 'cal-1', summary: 'Work');

      expect(cal.id, 'cal-1');
      expect(cal.summary, 'Work');
      expect(cal.isPrimary, false);
      expect(cal.backgroundColor, isNull);
      expect(cal.foregroundColor, isNull);
    });

    test('constructs with all fields', () {
      final cal = CalendarInfo(
        id: 'primary@gmail.com',
        summary: 'Primary Calendar',
        isPrimary: true,
        backgroundColor: '#0088aa',
        foregroundColor: '#ffffff',
      );

      expect(cal.id, 'primary@gmail.com');
      expect(cal.summary, 'Primary Calendar');
      expect(cal.isPrimary, true);
      expect(cal.backgroundColor, '#0088aa');
      expect(cal.foregroundColor, '#ffffff');
    });

    test('isPrimary defaults to false', () {
      final cal = CalendarInfo(id: 'x', summary: 'Shared');
      expect(cal.isPrimary, false);
    });
  });
}
