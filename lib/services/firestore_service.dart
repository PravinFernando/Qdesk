import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    return UserModel(
      uid: uid, // ✅ FIX: use passed uid
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}