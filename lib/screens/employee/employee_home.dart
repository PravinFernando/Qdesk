import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'attendance_screen.dart';
import 'reimbursement_screen.dart';
import 'my_reimbursements.dart';
import 'daily_sheet_screen.dart';
import '../common/change_password_screen.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('qdesk'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(),
        builder: (context, snapshot) {
          Map<String, dynamic> userData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          }

          final name = userData['name'] ?? 'Employee';
          final role = userData['role'] ?? 'employee';
          final code = userData['employeeCode']?.toString() ?? '-';
          final dept = userData['department'] ?? '-';
          final reportsTo = userData['reportsTo'] ?? '-';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Profile Header ────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    border: Border(
                      bottom: BorderSide(
                          color: Color(0xFF374151), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFD4AF37)
                                      .withOpacity(0.5)),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37)
                                        .withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFD4AF37)
                                            .withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info chips row
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.badge_outlined,
                              label: 'Emp Code',
                              value: '#$code',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.apartment_outlined,
                              label: 'Department',
                              value: dept,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.person_outline,
                              label: 'Reports To',
                              value: reportsTo.split(' ').first,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Menu Buttons ──────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _MenuButton(
                        icon: Icons.calendar_today,
                        label: 'Attendance',
                        subtitle: 'Check in, check out & calendar',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const AttendanceScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _MenuButton(
                        icon: Icons.edit_note,
                        label: 'Daily Sheet',
                        subtitle: 'Submit your daily work log',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const DailySheetScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _MenuButton(
                        icon: Icons.receipt_long,
                        label: 'Apply Reimbursement',
                        subtitle: 'Submit expense claims',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const ReimbursementScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _MenuButton(
                        icon: Icons.list_alt,
                        label: 'My Reimbursements',
                        subtitle: 'Track your submitted claims',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const MyReimbursements()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _MenuButton(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        subtitle: 'Update your login password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: Colors.white38),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20, color: const Color(0xFFD4AF37)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}