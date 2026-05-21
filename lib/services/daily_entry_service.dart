import 'package:cloud_firestore/cloud_firestore.dart';

class DailyEntryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Document ID = uid_YYYY-MM-DD
  String _docId(String uid, String date) => '${uid}_$date';

  // Today's date as "YYYY-MM-DD" (zero-padded)
  String getTodayDate() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  // Save or update today's daily entry
  Future<void> saveEntry({
    required String uid,
    required String date,
    required String workStatus,
    required double hours,
    required String comment,
  }) async {
    final docId = _docId(uid, date);
    await _db.collection('daily_entries').doc(docId).set({
      'uid': uid,
      'date': date,
      'workStatus': workStatus,
      'hours': hours,
      'comment': comment,
      'managerStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge so createdAt isn't overwritten on edit
  }

  // Get a single entry for a specific date
  Future<DocumentSnapshot> getEntry(String uid, String date) {
    return _db.collection('daily_entries').doc(_docId(uid, date)).get();
  }

  // Stream recent entries for the employee, ordered by date descending
  Stream<QuerySnapshot> getRecentEntries(String uid) {
    return _db
        .collection('daily_entries')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots();
  }
}