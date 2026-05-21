import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../employee/employee_home.dart';
import '../common/change_password_screen.dart';


class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'Switch to Employee Mode',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeHome()),
            ),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Attendance'),
            Tab(text: 'Daily Sheets'),
            Tab(text: 'Reimbursements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UsersTab(),
          _AttendanceTab(),
          _DailySheetsTab(),
          _ReimbursementsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — USERS
// ─────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _searchQuery = '';
  String _roleFilter = 'All';

  final List<String> _roles = ['All', 'admin', 'manager', 'employee'];

  Future<void> _toggleActive(String uid, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isActive': !current});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!current ? 'User activated' : 'User deactivated'),
        backgroundColor: !current
            ? const Color(0xFF4ADE80)
            : const Color(0xFFF87171),
      ),
    );
  }

  Future<void> _changeRole(
      BuildContext context, String uid, String currentRole) async {
    String selected = currentRole;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('Change Role',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['admin', 'manager', 'employee'].map((r) {
              return RadioListTile<String>(
                value: r,
                groupValue: selected,
                onChanged: (v) => set(() => selected = v!),
                title: Text(r,
                    style: const TextStyle(color: Colors.white)),
                activeColor: const Color(0xFFD4AF37),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'role': selected});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Role updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + filter
        Container(
          color: const Color(0xFF1F2937),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name or code',
                    hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF374151),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    dropdownColor: const Color(0xFF374151),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _roleFilter = v!),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('employeeCode')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;

              // Apply filters
              if (_roleFilter != 'All') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['role'] == _roleFilter;
                }).toList();
              }

              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                  (data['name'] ?? '').toString().toLowerCase();
                  final code =
                  (data['employeeCode'] ?? '').toString();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      code.contains(_searchQuery);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                  docs[index].data() as Map<String, dynamic>;
                  final uid = docs[index].id;
                  final isActive = data['isActive'] ?? true;
                  final role = data['role'] ?? 'employee';

                  Color roleColor;
                  if (role == 'admin') {
                    roleColor = const Color(0xFFF87171);
                  } else if (role == 'manager') {
                    roleColor = const Color(0xFFD4AF37);
                  } else {
                    roleColor = const Color(0xFF4ADE80);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? null
                          : Border.all(
                          color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        // Code badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${data['employeeCode'] ?? '-'}',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Unknown',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data['department'] ?? '-',
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        // Role badge
                        GestureDetector(
                          onTap: () =>
                              _changeRole(context, uid, role),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                  color: roleColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Active toggle
                        Switch(
                          value: isActive,
                          onChanged: (_) =>
                              _toggleActive(uid, isActive),
                          activeColor: const Color(0xFF4ADE80),
                        ),
                        IconButton(
                          icon: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37), size: 20),
                          tooltip: 'Reset Password',
                          onPressed: () => _resetPassword(context, data['email'] ?? ''),
                        ),

                      ],
                    ),

                  );
                },
              );
            },
          ),
        ),

      ],
    );

  }
  Future<void> _resetPassword(BuildContext context, String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reset link sent to $email'), backgroundColor: const Color(0xFF4ADE80)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — ATTENDANCE
// ─────────────────────────────────────────────────────────────

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _exportCSV(List<Map<String, dynamic>> rows) async {
    final lines = <String>[
      'Name,Employee Code,Department,Check In,Check Out,Status,Date'
    ];
    for (final r in rows) {
      lines.add(
          '"${r['name']}","${r['code']}","${r['dept']}","${r['checkIn']}","${r['checkOut']}","${r['status']}","${r['date']}"');
    }
    final csv = lines.join('\n');
    // Show CSV in dialog for copy
    _showExportDialog(csv);
  }

  void _showExportDialog(String csv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Export CSV',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDate(_selectedDate);

    return FutureBuilder<QuerySnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').get(),
      builder: (context, usersSnap) {
        if (!usersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<String, Map<String, dynamic>> userMap = {};
        for (var doc in usersSnap.data!.docs) {
          userMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('date', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, attSnap) {
            if (!attSnap.hasData) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            // Build attendance map uid → data
            final Map<String, Map<String, dynamic>> attMap = {};
            for (var doc in attSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['uid'] != null) {
                attMap[d['uid'] as String] = d;
              }
            }

            final allUsers = userMap.entries.toList()
              ..sort((a, b) => ((a.value['employeeCode'] ?? 0) as int)
                  .compareTo(
                  (b.value['employeeCode'] ?? 0) as int));

            int presentCount = 0;
            int absentCount = 0;

            final rows = <Map<String, dynamic>>[];
            for (final entry in allUsers) {
              final uid = entry.key;
              final user = entry.value;
              final att = attMap[uid];
              final isPresent = att != null &&
                  att['status'] == 'present';
              if (isPresent) presentCount++;
              else absentCount++;

              String checkIn = '--';
              String checkOut = '--';
              if (att?['checkIn'] != null) {
                checkIn = DateFormat('hh:mm a')
                    .format((att!['checkIn'] as Timestamp).toDate());
              }
              if (att?['checkOut'] != null) {
                checkOut = DateFormat('hh:mm a')
                    .format((att!['checkOut'] as Timestamp).toDate());
              }

              rows.add({
                'uid': uid,
                'name': user['name'] ?? '-',
                'code': user['employeeCode'] ?? '-',
                'dept': user['department'] ?? '-',
                'checkIn': checkIn,
                'checkOut': checkOut,
                'status': isPresent ? 'Present' : 'Absent',
                'date': dateKey,
              });
            }

            return Column(
              children: [
                // Date + export bar
                Container(
                  color: const Color(0xFF1F2937),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14,
                                    color: Color(0xFFD4AF37)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _exportCSV(rows),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary
                Container(
                  color: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _SummaryChip('Present', presentCount,
                          const Color(0xFF4ADE80)),
                      const SizedBox(width: 12),
                      _SummaryChip('Absent', absentCount,
                          const Color(0xFFF87171)),
                      const SizedBox(width: 12),
                      _SummaryChip(
                          'Total', allUsers.length, Colors.white54),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final r = rows[index];
                      final isPresent = r['status'] == 'Present';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPresent
                                ? const Color(0xFF4ADE80)
                                .withOpacity(0.3)
                                : const Color(0xFFF87171)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37)
                                    .withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text('${r['code']}',
                                    style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(r['name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 13)),
                                  Text(r['dept'],
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Text('In: ${r['checkIn']}',
                                    style: const TextStyle(
                                        color: Color(0xFF4ADE80),
                                        fontSize: 11)),
                                Text('Out: ${r['checkOut']}',
                                    style: const TextStyle(
                                        color: Color(0xFFF87171),
                                        fontSize: 11)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isPresent
                                    ? const Color(0xFF4ADE80)
                                    : const Color(0xFFF87171))
                                    .withOpacity(0.15),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                r['status'],
                                style: TextStyle(
                                  color: isPresent
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — DAILY SHEETS
// ─────────────────────────────────────────────────────────────

class _DailySheetsTab extends StatefulWidget {
  const _DailySheetsTab();

  @override
  State<_DailySheetsTab> createState() => _DailySheetsTabState();
}

class _DailySheetsTabState extends State<_DailySheetsTab> {
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'All';

  final List<String> _statuses = [
    'All', 'Assignment', 'WFH', 'Leave', 'Holiday', 'Training', 'Other'
  ];

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _exportCSV(List<Map<String, dynamic>> rows) {
    final lines = <String>[
      'Date,Name,Employee Code,Department,Status,Hours,Comment,Manager Status'
    ];
    for (final r in rows) {
      lines.add(
          '"${r['date']}","${r['name']}","${r['code']}","${r['dept']}","${r['workStatus']}","${r['hours']}","${r['comment']}","${r['managerStatus']}"');
    }
    _showExportDialog(lines.join('\n'));
  }

  void _showExportDialog(String csv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Export CSV',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(csv,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDate(_selectedDate);

    return FutureBuilder<QuerySnapshot>(
      future:
      FirebaseFirestore.instance.collection('users').get(),
      builder: (context, usersSnap) {
        if (!usersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<String, Map<String, dynamic>> userMap = {};
        for (var doc in usersSnap.data!.docs) {
          userMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('daily_entries')
              .where('date', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            var entries = snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final user = userMap[d['uid']] ?? {};
              return {
                'docId': doc.id,
                'date': d['date'] ?? '',
                'uid': d['uid'] ?? '',
                'name': user['name'] ?? 'Unknown',
                'code': user['employeeCode'] ?? '-',
                'dept': user['department'] ?? '-',
                'workStatus': d['workStatus'] ?? '-',
                'hours': d['hours'] ?? 0,
                'comment': d['comment'] ?? '',
                'managerStatus': d['managerStatus'] ?? 'pending',
              };
            }).toList();

            if (_statusFilter != 'All') {
              entries = entries
                  .where((e) => e['workStatus'] == _statusFilter)
                  .toList();
            }

            return Column(
              children: [
                Container(
                  color: const Color(0xFF1F2937),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF374151),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 14,
                                    color: Color(0xFFD4AF37)),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('dd MMM yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            dropdownColor: const Color(0xFF374151),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            items: _statuses
                                .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _statusFilter = v!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _exportCSV(
                            entries.cast<Map<String, dynamic>>()),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),

                entries.isEmpty
                    ? const Expanded(
                  child: Center(
                    child: Text('No entries for this date',
                        style:
                        TextStyle(color: Colors.white54)),
                  ),
                )
                    : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final mStatus = (e['managerStatus']
                      as String)
                          .toUpperCase();
                      Color mColor = mStatus == 'APPROVED'
                          ? const Color(0xFF4ADE80)
                          : mStatus == 'REJECTED'
                          ? const Color(0xFFF87171)
                          : const Color(0xFFFBBF24);

                      return Container(
                        margin:
                        const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _CodeBadge(
                                    '${e['code']}'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e['name'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _StatusBadge(
                                    mStatus, mColor),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _Tag(e['dept'] as String,
                                    Colors.blue),
                                const SizedBox(width: 6),
                                _Tag(
                                    e['workStatus'] as String,
                                    const Color(0xFFD4AF37)),
                                const SizedBox(width: 6),
                                _Tag(
                                    '${e['hours']} hrs',
                                    Colors.white54),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(e['comment'] as String,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4 — REIMBURSEMENTS
// ─────────────────────────────────────────────────────────────

class _ReimbursementsTab extends StatefulWidget {
  const _ReimbursementsTab();

  @override
  State<_ReimbursementsTab> createState() =>
      _ReimbursementsTabState();
}

class _ReimbursementsTabState extends State<_ReimbursementsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTab;
  String _selectedMonth = 'All';
  String _nameSearch = '';

  @override
  void initState() {
    super.initState();
    _subTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTab.dispose();
    super.dispose();
  }

  void _exportCSV(List<QueryDocumentSnapshot> docs) {
    final lines = <String>[
      'Name,Type,Amount,Date,Assignment,Status'
    ];
    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      lines.add(
          '"${d['name'] ?? ''}","${d['reimbursementType'] ?? ''}","${d['amount'] ?? ''}","${d['expenseDate'] ?? ''}","${d['assignmentName'] ?? ''}","${d['status'] ?? ''}"');
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Export CSV',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(lines.join('\n'),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reimbursements')
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          // Name filter
          if (_nameSearch.isNotEmpty) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            if (!name.contains(_nameSearch.toLowerCase())) return false;
          }
          // Month filter
          if (_selectedMonth != 'All') {
            final date = data['expenseDate'] ?? '';
            if (!date.startsWith(_selectedMonth)) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            if (docs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _exportCSV(docs),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                child: Text(
                  'No ${statusFilter} reimbursements',
                  style:
                  const TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final d = docs[index].data()
                  as Map<String, dynamic>;
                  final status = d['status'] ?? 'pending';
                  Color statusColor =
                  status == 'approved'
                      ? const Color(0xFF4ADE80)
                      : status == 'rejected'
                      ? const Color(0xFFF87171)
                      : const Color(0xFFFBBF24);

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            _StatusBadge(
                                status.toUpperCase(),
                                statusColor),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DetailRow('Type',
                            d['reimbursementType'] ?? '-'),
                        _DetailRow('Amount',
                            '₹${d['amount'] ?? 0}'),
                        _DetailRow(
                            'Date', d['expenseDate'] ?? '-'),
                        _DetailRow('Assignment',
                            d['assignmentName'] ?? '-'),
                        if ((d['imageUrl'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: const Color(0xFF1F2937),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(
                                        d['imageUrl'],
                                        fit: BoxFit.contain,
                                        loadingBuilder: (_, child, progress) => progress == null
                                            ? child
                                            : const Padding(
                                          padding: EdgeInsets.all(40),
                                          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close', style: TextStyle(color: Color(0xFFD4AF37))),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_outlined, color: Color(0xFFD4AF37), size: 16),
                                  SizedBox(width: 6),
                                  Text('View Receipt', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (statusFilter == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('reimbursements')
                                        .doc(docs[index].id)
                                        .update({'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4ADE80).withOpacity(0.2),
                                    foregroundColor: const Color(0xFF4ADE80),
                                    side: const BorderSide(color: Color(0xFF4ADE80)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('reimbursements')
                                        .doc(docs[index].id)
                                        .update({'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF87171).withOpacity(0.2),
                                    foregroundColor: const Color(0xFFF87171),
                                    side: const BorderSide(color: Color(0xFFF87171)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );

                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filters ──
        Container(
          color: const Color(0xFF111827),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _nameSearch = v),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF374151),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    dropdownColor: const Color(0xFF374151),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [
                      'All',
                      ...List.generate(12, (i) {
                        final d = DateTime(DateTime.now().year, i + 1);
                        return DateFormat('yyyy-MM').format(d);
                      })
                    ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFF1F2937),
          child: TabBar(
            controller: _subTab,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTab,
            children: [
              _buildList('pending'),
              _buildList('approved'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style:
              TextStyle(color: color, fontSize: 11)),
          Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String code;
  const _CodeBadge(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('#$code',
          style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}