import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  String getTodayDocId(String uid) {

    final now = DateTime.now();
    final date = "${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}";

    return "${uid}_$date";
  }

  Future checkIn(String uid) async {

    final now = DateTime.now();

    final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final docId = getTodayDocId(uid);

    final docRef =
    firestore.collection("attendance")
        .doc(docId);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      throw Exception(
        "Already checked in today",
      );
    }

    await docRef.set({

      "uid": uid,

      "date": today,

      "status": "present",

      "checkIn":
      FieldValue.serverTimestamp(),

      "checkOut": null,

      "dailySummary": "",

      "leaveRequested": false,

      "managerStatus": "pending",
    });
  }

  Future checkOut(String uid) async {

    final docId = getTodayDocId(uid);

    final docRef =
    firestore.collection("attendance")
        .doc(docId);

    await docRef.update({

      "checkOut":
      FieldValue.serverTimestamp(),

    });
  }

  Stream<DocumentSnapshot>
  getTodayAttendance(String uid) {

    final docId = getTodayDocId(uid);

    return firestore
        .collection("attendance")
        .doc(docId)
        .snapshots();
  }
}