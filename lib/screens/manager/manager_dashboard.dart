import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../employee/employee_home.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Manager's own name — used to filter team members
  String _managerName = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadManagerName();
  }

  Future<void> _loadManagerName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _managerName = data['name'] ?? '';
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
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
          tabs: const [
            Tab(text: 'Daily Sheet'),
            //Tab(text: 'Reimbursements'),
            Tab(text: 'Missing Entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TeamDailySheetTab(managerName: _managerName),
          //_ReimbursementsTab(managerName: _managerName),
          _MissingEntriesTab(managerName: _managerName),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — TEAM DAILY SHEET
// ─────────────────────────────────────────────────────────────

class _TeamDailySheetTab extends StatefulWidget {
  final String managerName;
  const _TeamDailySheetTab({required this.managerName});

  @override
  State<_TeamDailySheetTab> createState() => _TeamDailySheetTabState();
}

class _TeamDailySheetTabState extends State<_TeamDailySheetTab> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = [
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

  Future<void> _showReviewDialog(
      BuildContext context, String docId, String employeeName) async {
    final commentController = TextEditingController();
    String action = 'approved';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: Text('Review — $employeeName',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialogState(() => action = 'approved'),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: action == 'approved'
                              ? const Color(0xFF4ADE80).withOpacity(0.2)
                              : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(8),
                          border: action == 'approved'
                              ? Border.all(color: const Color(0xFF4ADE80))
                              : null,
                        ),
                        child: Center(
                          child: Text('Approve',
                              style: TextStyle(
                                color: action == 'approved'
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialogState(() => action = 'rejected'),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: action == 'rejected'
                              ? const Color(0xFFF87171).withOpacity(0.2)
                              : const Color(0xFF374151),
                          borderRadius: BorderRadius.circular(8),
                          border: action == 'rejected'
                              ? Border.all(color: const Color(0xFFF87171))
                              : null,
                        ),
                        child: Center(
                          child: Text('Reject',
                              style: TextStyle(
                                color: action == 'rejected'
                                    ? const Color(0xFFF87171)
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a comment (optional)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF374151),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
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
                    .collection('daily_entries')
                    .doc(docId)
                    .update({
                  'managerStatus': action,
                  'managerComment': commentController.text.trim(),
                  'reviewedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(action == 'approved'
                        ? 'Entry Approved'
                        : 'Entry Rejected'),
                    backgroundColor: action == 'approved'
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF87171),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDate(_selectedDate);

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, usersSnap) {
        if (!usersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Build uid → user map
        final Map<String, Map<String, dynamic>> userMap = {};
        for (var doc in usersSnap.data!.docs) {
          userMap[doc.id] = doc.data() as Map<String, dynamic>;
        }

        // Only UIDs of people who report to THIS manager
        final myTeamUids = userMap.entries
            .where((e) => e.value['reportsTo'] == widget.managerName)
            .map((e) => e.key)
            .toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('daily_entries')
              .where('date', isEqualTo: dateKey)
              .snapshots(),
          builder: (context, entriesSnap) {
            if (!entriesSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter to only my team's entries
            var entries = entriesSnap.data!.docs
                .where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return myTeamUids.contains(d['uid']);
            })
                .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final user = userMap[data['uid']] ?? {};
              return {
                'docId': doc.id,
                'uid': data['uid'] ?? '',
                'date': data['date'] ?? '',
                'workStatus': data['workStatus'] ?? '',
                'hours': data['hours'] ?? 0,
                'comment': data['comment'] ?? '',
                'managerStatus': data['managerStatus'] ?? 'pending',
                'name': user['name'] ?? 'Unknown',
                'employeeCode': user['employeeCode'] ?? '-',
                'department': user['department'] ?? '-',
              };
            })
                .toList();

            // Search filter
            if (_searchQuery.isNotEmpty) {
              entries = entries.where((e) {
                final name = e['name'].toString().toLowerCase();
                final code = e['employeeCode'].toString();
                return name.contains(_searchQuery.toLowerCase()) ||
                    code.contains(_searchQuery);
              }).toList();
            }

            // Status filter
            if (_statusFilter != 'All') {
              entries = entries
                  .where((e) => e['workStatus'] == _statusFilter)
                  .toList();
            }

            // Summary counts (from full team entries before filters)
            final allTeamEntries = entriesSnap.data!.docs
                .where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return myTeamUids.contains(d['uid']);
            })
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            final counts = <String, int>{};
            for (var e in allTeamEntries) {
              final s = e['workStatus'] ?? 'Other';
              counts[s] = (counts[s] ?? 0) + 1;
            }

            return Column(
              children: [
                // Filters
                Container(
                  color: const Color(0xFF1F2937),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
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
                                      DateFormat('dd/MM/yyyy')
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
                                isExpanded: false,
                                items: _statusOptions
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or employee code',
                          hintStyle: const TextStyle(
                              color: Colors.white38, fontSize: 13),
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
                    ],
                  ),
                ),

                // Summary counts
                Container(
                  color: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Assignment', 'WFH', 'Leave',
                        'Holiday', 'Training', 'Other'
                      ].map((s) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF374151)),
                          ),
                          child: Column(
                            children: [
                              Text(s,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                '${counts[s] ?? 0}',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Entries list
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                    child: Text(
                      myTeamUids.isEmpty
                          ? 'No team members assigned to you'
                          : 'No entries for this date',
                      style: const TextStyle(
                          color: Colors.white54),
                    ),
                  )
                      : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final e = entries[index];
                      final status = e['managerStatus']
                          .toString()
                          .toUpperCase();

                      Color statusColor;
                      if (status == 'APPROVED') {
                        statusColor = const Color(0xFF4ADE80);
                      } else if (status == 'REJECTED') {
                        statusColor = const Color(0xFFF87171);
                      } else {
                        statusColor = const Color(0xFFFBBF24);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _CodeBadge(
                                    '${e['employeeCode']}'),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e['name'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _StatusBadge(
                                    status, statusColor),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _Tag(e['department'].toString(),
                                    Colors.blue),
                                const SizedBox(width: 6),
                                _Tag(e['workStatus'].toString(),
                                    const Color(0xFFD4AF37)),
                                const SizedBox(width: 6),
                                _Tag('${e['hours']} hrs',
                                    Colors.white54),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e['comment'].toString(),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _showReviewDialog(
                                      context,
                                      e['docId'].toString(),
                                      e['name'].toString(),
                                    ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFFD4AF37)),
                                  foregroundColor:
                                  const Color(0xFFD4AF37),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Add Review'),
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
// TAB 2 — REIMBURSEMENTS
// ─────────────────────────────────────────────────────────────

class _ReimbursementsTab extends StatefulWidget {
  final String managerName;
  const _ReimbursementsTab({required this.managerName});

  @override
  State<_ReimbursementsTab> createState() =>
      _ReimbursementsTabState();
}

class _ReimbursementsTabState extends State<_ReimbursementsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTab;

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

  Future<void> _updateStatus(
      BuildContext context, String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('reimbursements')
        .doc(docId)
        .update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reimbursement $status'),
        backgroundColor: status == 'approved'
            ? const Color(0xFF4ADE80)
            : const Color(0xFFF87171),
      ),
    );
  }

  Widget _buildList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reimbursements')
          .where('reportsTo', isEqualTo: widget.managerName)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }


        final docs = snapshot.data!.docs
            .where((d) => (d.data() as Map<String, dynamic>)['status'] == statusFilter)
            .toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              statusFilter == 'pending'
                  ? 'No pending reimbursements'
                  : 'No history yet',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final status = data['status'] ?? 'pending';

            Color statusColor = status == 'approved'
                ? const Color(0xFF4ADE80)
                : status == 'rejected'
                ? const Color(0xFFF87171)
                : const Color(0xFFFBBF24);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusBadge(status.toUpperCase(), statusColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DetailRow('Type',
                      data['reimbursementType'] ?? '-'),
                  _DetailRow('Amount', '₹${data['amount'] ?? 0}'),
                  _DetailRow('Date', data['expenseDate'] ?? '-'),
                  _DetailRow(
                      'Assignment', data['assignmentName'] ?? '-'),
                  if ((data['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(data['description'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                  if (statusFilter == 'pending') ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(
                                context, docId, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ADE80)
                                  .withOpacity(0.2),
                              foregroundColor:
                              const Color(0xFF4ADE80),
                              side: const BorderSide(
                                  color: Color(0xFF4ADE80)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8)),
                            ),
                            child: const Text('Approve'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(
                                context, docId, 'rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF87171)
                                  .withOpacity(0.2),
                              foregroundColor:
                              const Color(0xFFF87171),
                              side: const BorderSide(
                                  color: Color(0xFFF87171)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8)),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
// TAB 3 — MISSING ENTRIES
// ─────────────────────────────────────────────────────────────

class _MissingEntriesTab extends StatefulWidget {
  final String managerName;
  const _MissingEntriesTab({required this.managerName});

  @override
  State<_MissingEntriesTab> createState() =>
      _MissingEntriesTabState();
}

class _MissingEntriesTabState extends State<_MissingEntriesTab> {
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

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDate(_selectedDate);

    return Column(
      children: [
        Container(
          color: const Color(0xFF1F2937),
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  Text(
                    'Checking: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .where('reportsTo', isEqualTo: widget.managerName)
                .get(),
            builder: (context, usersSnap) {
              if (!usersSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final myTeam = usersSnap.data!.docs;

              if (myTeam.isEmpty) {
                return const Center(
                  child: Text('No team members assigned to you',
                      style: TextStyle(color: Colors.white54)),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_entries')
                    .where('date', isEqualTo: dateKey)
                    .snapshots(),
                builder: (context, entriesSnap) {
                  if (!entriesSnap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final submittedUids = entriesSnap.data!.docs
                      .map((d) => (d.data()
                  as Map<String, dynamic>)['uid']
                  as String)
                      .toSet();

                  final missing = myTeam.where((doc) {
                    return !submittedUids.contains(doc.id);
                  }).toList();

                  if (missing.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF4ADE80), size: 48),
                          SizedBox(height: 12),
                          Text('All team members submitted!',
                              style: TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: Color(0xFFF87171), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${missing.length} member(s) missing entry',
                              style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12),
                          itemCount: missing.length,
                          itemBuilder: (context, index) {
                            final data = missing[index].data()
                            as Map<String, dynamic>;
                            return Container(
                              margin:
                              const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F2937),
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFF87171)
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  _CodeBadge(
                                      '${data['employeeCode'] ?? '-'}'),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                              FontWeight.bold),
                                        ),
                                        Text(
                                          data['department'] ?? '-',
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.cancel_outlined,
                                      color: Color(0xFFF87171),
                                      size: 20),
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
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

class _CodeBadge extends StatelessWidget {
  final String code;
  const _CodeBadge(this.code);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
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
              style:
              const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}