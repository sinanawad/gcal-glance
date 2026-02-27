import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gcal_glance/config/crt_theme.dart';
import 'package:gcal_glance/models/calendar_info.dart';

class CalendarPicker extends StatelessWidget {
  final List<CalendarInfo> calendars;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onClose;

  const CalendarPicker({
    super.key,
    required this.calendars,
    required this.selectedIds,
    required this.onToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps on dialog
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: CrtTheme.background,
                border: Border.all(color: CrtTheme.textSecondary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text(
                      'CALENDARS',
                      style: GoogleFonts.vt323(
                        fontSize: 28,
                        color: CrtTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: CrtTheme.textSecondary.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // Calendar list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: calendars.length,
                      itemBuilder: (context, index) {
                        final cal = calendars[index];
                        final isSelected = selectedIds.contains(cal.id);
                        final colorValue =
                            _parseHexColor(cal.backgroundColor);
                        final dotColor = colorValue != null
                            ? CrtTheme.fadedCalendarColor(colorValue)
                            : CrtTheme.textSecondary;

                        return InkWell(
                          onTap: cal.isPrimary ? null : () => onToggle(cal.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                // Color dot
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Calendar name
                                Expanded(
                                  child: Text(
                                    cal.isPrimary
                                        ? '${cal.summary} (primary)'
                                        : cal.summary,
                                    style: GoogleFonts.vt323(
                                      fontSize: 22,
                                      color: isSelected
                                          ? CrtTheme.textPrimary
                                          : CrtTheme.textSecondary
                                              .withValues(alpha: 0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Checkbox
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: cal.isPrimary
                                        ? null
                                        : (_) => onToggle(cal.id),
                                    activeColor: CrtTheme.ongoing,
                                    checkColor: CrtTheme.background,
                                    side: BorderSide(
                                      color: CrtTheme.textSecondary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    height: 1,
                    color: CrtTheme.textSecondary.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Press C or ESC to close',
                      style: GoogleFonts.vt323(
                        fontSize: 16,
                        color: CrtTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static int? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    return int.tryParse('FF$cleaned', radix: 16);
  }
}
