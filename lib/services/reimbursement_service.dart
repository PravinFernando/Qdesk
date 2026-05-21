import 'package:cloud_firestore/cloud_firestore.dart';

class ReimbursementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> submitReimbursement(Map<String, dynamic> data) async {
    await _db.collection('reimbursements').add({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}