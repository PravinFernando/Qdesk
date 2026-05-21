import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// Reimbursement Screen  (fully redesigned)
// • Auto-fills Name + Employee ID from Firestore
// • Dark-gold theme consistent with the rest of the app
// ─────────────────────────────────────────────

class ReimbursementScreen extends StatefulWidget {
  const ReimbursementScreen({super.key});

  @override
  State<ReimbursementScreen> createState() => _ReimbursementScreenState();
}

class _ReimbursementScreenState extends State<ReimbursementScreen> {
  // ── Constants ──────────────────────────────
  static const _bg       = Color(0xFF0B1020);
  static const _surface  = Color(0xFF1F2937);
  static const _card     = Color(0xFF111827);
  static const _gold     = Color(0xFFD4AF37);
  static const _border   = Color(0xFF374151);
  static const _textMid  = Color(0xFF9CA3AF);

  // ── Form ───────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // Read-only auto-filled
  final _nameCtrl       = TextEditingController();
  final _empIdCtrl      = TextEditingController();

  // User-filled
  final _descCtrl       = TextEditingController();
  final _assignmentCtrl = TextEditingController();
  final _amountCtrl     = TextEditingController();

  String   _reportsTo    = '';
  String   _type         = 'Food';
  DateTime _expenseDate  = DateTime.now();
  File?    _receipt;
  bool     _loading      = false;
  bool     _userLoading  = true;   // while Firestore user fetch is in progress

  final _types = ['Food', 'Travel', 'Accommodation', 'Fuel', 'Other'];

  // ── Icons per type ─────────────────────────
  static const _typeIcons = {
    'Food'          : Icons.restaurant_outlined,
    'Travel'        : Icons.directions_bus_outlined,
    'Accommodation' : Icons.hotel_outlined,
    'Fuel'          : Icons.local_gas_station_outlined,
    'Other'         : Icons.receipt_outlined,
  };

  // ── Lifecycle ──────────────────────────────
  @override
  void initState() {
    super.initState();
    _autoFillUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _empIdCtrl.dispose();
    _descCtrl.dispose();
    _assignmentCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Auto-fill name + employee code ─────────
  Future<void> _autoFillUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _nameCtrl.text  = d['name']         ?? '';
        _empIdCtrl.text = d['employeeCode']?.toString() ?? '';
        _reportsTo      = d['reportsTo']    ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _userLoading = false);
  }

  // ── Pick receipt image ──────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFD4AF37)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _receipt = File(picked.path));
  }

  // ── Upload receipt to Firebase Storage ─────
  Future<String> _uploadReceipt() async {
    if (_receipt == null) return '';
    try {
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref  = FirebaseStorage.instance
          .ref()
          .child('receipts')
          .child(name);
      final snap = await ref.putFile(_receipt!);
      return await snap.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return '';
    }
  }

  // ── Submit ─────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid      = FirebaseAuth.instance.currentUser!.uid;
      final imageUrl = await _uploadReceipt();

      await FirebaseFirestore.instance
          .collection('reimbursements')
          .add({
        'uid'              : uid,
        'name'             : _nameCtrl.text.trim(),
        'employeeId'       : _empIdCtrl.text.trim(),
        'reimbursementType': _type,
        'expenseDate'      : DateFormat('yyyy-MM-dd').format(_expenseDate),
        'description'      : _descCtrl.text.trim(),
        'assignmentName'   : _assignmentCtrl.text.trim(),
        'amount'           : double.parse(_amountCtrl.text.trim()),
        'imageUrl'         : imageUrl,
        'reportsTo'        : _reportsTo,
        'status'           : 'pending',
        'createdAt'        : FieldValue.serverTimestamp(),
        'reviewedBy'       : null,
        'reviewedAt'       : null,
      });

      if (mounted) {
        _showSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 18),
          SizedBox(width: 10),
          Text('Reimbursement submitted successfully'),
        ]),
        backgroundColor: const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF991B1B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Date picker ────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            surface: _surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expenseDate = picked);
  }

  // ── UI ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apply Reimbursement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: _userLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section: Employee Info ──────────────
              _SectionLabel(label: 'EMPLOYEE INFO'),
              const SizedBox(height: 12),

              _ReadOnlyField(
                label: 'Employee Name',
                value: _nameCtrl.text,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),

              _ReadOnlyField(
                label: 'Employee ID',
                value: _empIdCtrl.text.isEmpty ? '—' : '#${_empIdCtrl.text}',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 24),

              // ── Section: Expense Details ────────────
              _SectionLabel(label: 'EXPENSE DETAILS'),
              const SizedBox(height: 12),

              // Expense type chips
              _label('Type of Expense'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final selected = t == _type;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? _gold.withOpacity(0.15)
                            : _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? _gold.withOpacity(0.7)
                              : _border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _typeIcons[t],
                            size: 14,
                            color: selected ? _gold : _textMid,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t,
                            style: TextStyle(
                              color: selected ? _gold : _textMid,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Date picker
              _label('Expense Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: _gold),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM yyyy').format(_expenseDate),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: _textMid),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              _StyledField(
                controller: _amountCtrl,
                label: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Assignment
              _StyledField(
                controller: _assignmentCtrl,
                label: 'Assignment / College',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 16),

              // Description
              _StyledField(
                controller: _descCtrl,
                label: 'Description',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Section: Receipt ────────────────────
              _SectionLabel(label: 'RECEIPT'),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: _receipt != null ? null : 110,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _receipt != null
                          ? _gold.withOpacity(0.5)
                          : _border,
                      width: _receipt != null ? 1.5 : 1,
                    ),
                  ),
                  child: _receipt != null
                      ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(_receipt!,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _receipt = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.upload_outlined,
                            color: _gold, size: 22),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap to upload receipt',
                          style: TextStyle(
                              color: _textMid, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('JPG, PNG supported',
                          style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: _gold.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                      : const Text(
                    'Submit Reimbursement',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
  );
}

// ─────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4)),
        const SizedBox(width: 10),
        const Expanded(
            child: Divider(color: Color(0xFF374151), height: 1)),
      ],
    );
  }
}

// Auto-filled read-only display tile
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B7280), fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'Loading...' : value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Auto',
                style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Styled text form field
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon:
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFF1F2937),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}