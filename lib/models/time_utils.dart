class TimeUtils {
  static String formatDuration(Duration d) {
    if (d.inHours > 0 || d.inMinutes > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }
    return '${d.inSeconds}s';
  }
}
