import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/daily_entry_service.dart';

class DailySheetScreen extends StatefulWidget {
  const DailySheetScreen({super.key});

  @override
  State<DailySheetScreen> createState() => _DailySheetScreenState();
}

class _DailySheetScreenState extends State<DailySheetScreen> {
  final _commentController = TextEditingController();
  final DailyEntryService _dailyEntryService = DailyEntryService();

  late DateTime _selectedDate;
  String _workStatus = 'Assignment';
  double _hours = 8.0;
  bool _isSaving = false;
  int _currentPage = 1;
  final int _pageSize = 5;

  final List<String> _workStatuses = [
    'Assignment', 'WFH', 'Leave', 'Holiday', 'Training', 'Other',
  ];

  // Last 7 days including today
  late List<DateTime> _last7Days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _last7Days = List.generate(
      7,
          (i) => DateTime(now.year, now.month, now.day - i),
    );
    _loadEntryForDate(_selectedDate);
  }

  String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _loadEntryForDate(DateTime date) async {
    // Reset form first
    setState(() {
      _workStatus = 'Assignment';
      _hours = 8.0;
      _commentController.text = '';
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _dailyEntryService.getEntry(uid, _dateKey(date));
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _workStatus = data['workStatus'] ?? 'Assignment';
        _hours = (data['hours'] ?? 8.0).toDouble();
        _commentController.text = data['comment'] ?? '';
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a daily comment')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _dailyEntryService.saveEntry(
        uid: uid,
        date: _dateKey(_selectedDate),
        workStatus: _workStatus,
        hours: _hours,
        comment: _commentController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved successfully'),
          backgroundColor: Color(0xFF4ADE80),
        ),

      );_commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isSaving = false);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isToday = _dateKey(_selectedDate) == _dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Sheet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ───────────────────────────────────
            const Text(
              'Daily Sheet & Notes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Submit your daily work log for the last 7 days.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ── 7-Day Date Picker ─────────────────────────
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _last7Days.length,
                itemBuilder: (context, index) {
                  final date = _last7Days[index];
                  final isSelected =
                      _dateKey(date) == _dateKey(_selectedDate);
                  final isDateToday =
                      _dateKey(date) == _dateKey(DateTime.now());

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadEntryForDate(date);
                    },
                    child: Container(
                      width: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(12),
                        border: isDateToday && !isSelected
                            ? Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isDateToday)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black54
                                    : const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Form card ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Selected date display
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 6),
                      Text(
                        isToday
                            ? 'Today — ${DateFormat('dd MMM yyyy').format(_selectedDate)}'
                            : DateFormat('EEEE, dd MMM yyyy')
                            .format(_selectedDate),
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status + Hours
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Status'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _workStatus,
                                  dropdownColor: const Color(0xFF374151),
                                  style: const TextStyle(
                                      color: Colors.white),
                                  isExpanded: true,
                                  items: _workStatuses
                                      .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ))
                                      .toList(),
                                  onChanged: (val) => setState(() {
                                    _workStatus = val!;

                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _formLabel('Hours'),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF374151),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<double>(
                                  value: _hours,
                                  dropdownColor: const Color(0xFF374151),
                                  style: const TextStyle(
                                      color: Colors.white),
                                  isExpanded: true,
                                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
                                      .map((h) => DropdownMenuItem(
                                    value: h.toDouble(),
                                    child: Text('$h.0'),
                                  ))
                                      .toList(),
                                  onChanged: (_workStatus == 'Leave' || _workStatus == 'Holiday')
                                      ? null
                                      : (val) => setState(() => _hours = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Comment
                  _formLabel('Daily Comment / Summary *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'What did you work on?',
                      hintStyle:
                      const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF374151),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black),
                      )
                          : Text(
                        isToday
                            ? 'Save Today\'s Entry'
                            : 'Save Entry for ${DateFormat('dd MMM').format(_selectedDate)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Recent Entries ────────────────────────────
            const Text(
              'Recent Entries',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _dailyEntryService.getRecentEntries(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!.docs;

                if (allDocs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No entries yet',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }

                final totalPages =
                (allDocs.length / _pageSize).ceil();
                final start = (_currentPage - 1) * _pageSize;
                final end =
                (start + _pageSize).clamp(0, allDocs.length);
                final pageDocs = allDocs.sublist(start, end);

                return Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: const [
                                Expanded(
                                    flex: 3,
                                    child: _TableHeader('Date')),
                                Expanded(
                                    flex: 3,
                                    child: _TableHeader('Status')),
                                Expanded(
                                    flex: 1,
                                    child: _TableHeader('Hrs')),
                                Expanded(
                                    flex: 4,
                                    child: _TableHeader('Comment')),
                                Expanded(
                                    flex: 3,
                                    child:
                                    _TableHeader('Mgr Status')),
                              ],
                            ),
                          ),
                          const Divider(
                              color: Color(0xFF374151), height: 1),
                          ...pageDocs.map((doc) {
                            final d =
                            doc.data() as Map<String, dynamic>;
                            final status =
                            (d['managerStatus'] ?? 'pending')
                                .toString()
                                .toUpperCase();

                            Color statusColor;
                            if (status == 'APPROVED') {
                              statusColor =
                              const Color(0xFF4ADE80);
                            } else if (status == 'REJECTED') {
                              statusColor =
                              const Color(0xFFF87171);
                            } else {
                              statusColor =
                              const Color(0xFFFBBF24);
                            }

                            return Column(
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          d['date'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          d['workStatus'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '${d['hours'] ?? 0}',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          d['comment'] ?? '',
                                          maxLines: 2,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withOpacity(0.15),
                                            borderRadius:
                                            BorderRadius.circular(
                                                20),
                                            border: Border.all(
                                                color: statusColor
                                                    .withOpacity(
                                                    0.4)),
                                          ),
                                          child: Text(
                                            status,
                                            textAlign:
                                            TextAlign.center,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                    color: Color(0xFF374151),
                                    height: 1),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),

                    if (totalPages > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _currentPage > 1
                                ? () =>
                                setState(() => _currentPage--)
                                : null,
                            child: const Text('Prev'),
                          ),
                          Text(
                            'Page $_currentPage of $totalPages',
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13),
                          ),
                          TextButton(
                            onPressed: _currentPage < totalPages
                                ? () =>
                                setState(() => _currentPage++)
                                : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500),
  );
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 12,
          fontWeight: FontWeight.bold),
    );
  }
}