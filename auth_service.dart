import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name);
      await _db.collection(Collections.users).doc(user.uid).set({
        'name': name,
        'email': email.trim(),
        'photoUrl': '',
        'bio': '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return user;
  }

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await setOnlineStatus(true);
    return cred.user;
  }

  Future<void> logout() async {
    await setOnlineStatus(false);
    await _auth.signOut();
  }

  /// Call this from app lifecycle hooks (see main.dart) so presence
  /// stays accurate as the user backgrounds/foregrounds the app.
  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection(Collections.users).doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
