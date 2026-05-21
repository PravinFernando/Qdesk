import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceCalendar extends StatelessWidget {
  final String uid;

  const AttendanceCalendar({
    super.key,
    required this.uid,
  });

  // Returns "YYYY-MM-DD" with zero-padded month and day — must match
  // how AttendanceService writes the "date" field in Firestore.
  String _dateKey(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Day-of-week the month starts on (Monday=1 … Sunday=7, we want Sunday=0)
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0, Mon=1…
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Total cells = leading empty slots + actual days
    final totalCells = firstWeekday + daysInMonth;

    final monthLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Build attendance lookup map
        final Map<String, Map<String, dynamic>> attendanceMap = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] != null) {
              attendanceMap[data['date'] as String] = data;
            }
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Month title ──────────────────────────────
              Text(
                monthLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // ── Legend ───────────────────────────────────
              Row(
                children: [
                  _legendDot(const Color(0xFF4ADE80)),
                  const SizedBox(width: 4),
                  const Text('Present',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFF87171)),
                  const SizedBox(width: 4),
                  const Text('Absent',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFFBBF24)),
                  const SizedBox(width: 4),
                  const Text('Leave',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),

              // ── Day-of-week headers ──────────────────────
              const Row(
                children: [
                  _DayLabel('Sun'),
                  _DayLabel('Mon'),
                  _DayLabel('Tue'),
                  _DayLabel('Wed'),
                  _DayLabel('Thu'),
                  _DayLabel('Fri'),
                  _DayLabel('Sat'),
                ],
              ),
              const SizedBox(height: 8),

              // ── Calendar grid ────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  // Leading empty cells
                  if (index < firstWeekday) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstWeekday + 1;
                  final dateKey = _dateKey(year, month, day);
                  final data = attendanceMap[dateKey];

                  final isToday = now.day == day &&
                      now.month == month &&
                      now.year == year;

                  final isFuture =
                      DateTime(year, month, day).isAfter(now) && !isToday;

                  // Pick background colour
                  Color bgColor;
                  Color textColor;

                  if (isFuture) {
                    bgColor = const Color(0xFF374151); // dark grey – future
                    textColor = Colors.white38;
                  } else if (data == null) {
                    bgColor = const Color(0xFFF87171).withOpacity(0.25); // absent
                    textColor = const Color(0xFFF87171);
                  } else if (data['leaveRequested'] == true) {
                    bgColor = const Color(0xFFFBBF24).withOpacity(0.25);
                    textColor = const Color(0xFFFBBF24);
                  } else if (data['status'] == 'present') {
                    bgColor = const Color(0xFF4ADE80).withOpacity(0.2);
                    textColor = const Color(0xFF4ADE80);
                  } else {
                    bgColor = const Color(0xFFF87171).withOpacity(0.25);
                    textColor = const Color(0xFFF87171);
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 2,
                      )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isToday
                              ? const Color(0xFFD4AF37)
                              : textColor,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// Immutable helper — one column header
class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}