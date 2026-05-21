import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// My Reimbursements  (fully redesigned)
// • Summary totals bar at top
// • Rich cards with type icon, amount, date, status
// • Status-aware colour coding (gold pending, green, red)
// ─────────────────────────────────────────────

class MyReimbursements extends StatelessWidget {
  const MyReimbursements({super.key});

  // ── Colours ────────────────────────────────
  static const _bg      = Color(0xFF0B1020);
  static const _card    = Color(0xFF111827);
  static const _surface = Color(0xFF1F2937);
  static const _gold    = Color(0xFFD4AF37);
  static const _border  = Color(0xFF374151);

  // ── Status helpers ─────────────────────────
  static Color _statusColor(String s) {
    switch (s) {
      case 'approved': return const Color(0xFF4ADE80);
      case 'rejected': return const Color(0xFFF87171);
      default:         return _gold;
    }
  }

  static IconData _statusIcon(String s) {
    switch (s) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default:         return Icons.hourglass_top_outlined;
    }
  }

  // ── Type icons ─────────────────────────────
  static IconData _typeIcon(String t) {
    switch (t) {
      case 'Food':          return Icons.restaurant_outlined;
      case 'Travel':        return Icons.directions_bus_outlined;
      case 'Accommodation': return Icons.hotel_outlined;
      case 'Fuel':          return Icons.local_gas_station_outlined;
      default:              return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Reimbursements',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reimbursements')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _gold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final docs = snapshot.data!.docs;

          // Compute summary totals
          double totalAmt      = 0;
          double approvedAmt   = 0;
          double pendingAmt    = 0;
          for (final d in docs) {
            final data   = d.data() as Map<String, dynamic>;
            final amt    = (data['amount'] ?? 0).toDouble();
            final status = data['status'] ?? 'pending';
            totalAmt += amt;
            if (status == 'approved') approvedAmt += amt;
            if (status == 'pending')  pendingAmt  += amt;
          }

          return Column(
            children: [
              // ── Summary strip ───────────────────
              Container(
                color: _card,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    _SummaryTile(
                      label: 'Total',
                      amount: totalAmt,
                      color: Colors.white,
                    ),
                    _vDivider(),
                    _SummaryTile(
                      label: 'Approved',
                      amount: approvedAmt,
                      color: const Color(0xFF4ADE80),
                    ),
                    _vDivider(),
                    _SummaryTile(
                      label: 'Pending',
                      amount: pendingAmt,
                      color: _gold,
                    ),
                    _vDivider(),
                    _SummaryTile(
                      label: 'Claims',
                      count: docs.length,
                      color: const Color(0xFF60A5FA),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: _border),

              // ── List ────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data =
                    docs[i].data() as Map<String, dynamic>;
                    return _ReimbursementCard(data: data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 32,
    color: _border,
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );
}

// ─────────────────────────────────────────────
// Individual Card
// ─────────────────────────────────────────────

class _ReimbursementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ReimbursementCard({required this.data});

  static const _surface = Color(0xFF1F2937);
  static const _gold    = Color(0xFFD4AF37);
  static const _border  = Color(0xFF374151);

  @override
  Widget build(BuildContext context) {
    final type       = data['reimbursementType'] ?? 'Other';
    final status     = data['status']            ?? 'pending';
    final amount     = (data['amount']           ?? 0).toDouble();
    final dateStr    = data['expenseDate']        ?? '';
    final assignment = data['assignmentName']     ?? '';
    final desc       = data['description']        ?? '';
    final statusColor = MyReimbursements._statusColor(status);

    // Format date nicely if possible
    String formattedDate = dateStr;
    try {
      formattedDate =
          DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // ── Top row ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                // Type icon bubble
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    MyReimbursements._typeIcon(type),
                    color: _gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Type + assignment
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (assignment.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          assignment,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                Text(
                  '₹${NumberFormat('#,##0.00').format(amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────
          Container(height: 1, color: _border),

          // ── Bottom row ────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 5),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),

                const Spacer(),

                // Description preview
                if (desc.isNotEmpty)
                  Flexible(
                    child: Text(
                      desc,
                      style: const TextStyle(
                          color: Color(0xFF6B7280), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                const SizedBox(width: 10),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MyReimbursements._statusIcon(status),
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary tile in the top strip
// ─────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final double? amount;
  final int?    count;
  final Color   color;

  const _SummaryTile({
    required this.label,
    required this.color,
    this.amount,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final value = count != null
        ? '$count'
        : '₹${NumberFormat('#,##0').format(amount ?? 0)}';

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF6B7280), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Color(0xFFD4AF37), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reimbursements yet',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your submitted claims will appear here',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
        ],
      ),
    );
  }
}