/// Represents a Google Calendar visible to the user.
/// Used for the calendar picker UI and multi-calendar event fetching.
class CalendarInfo {
  final String id;
  final String summary;
  final bool isPrimary;
  final String? backgroundColor;
  final String? foregroundColor;

  const CalendarInfo({
    required this.id,
    required this.summary,
    this.isPrimary = false,
    this.backgroundColor,
    this.foregroundColor,
  });
}
