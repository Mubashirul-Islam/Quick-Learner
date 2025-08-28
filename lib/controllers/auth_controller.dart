import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxBool isLoading = true.obs;
  final Rxn<dynamic> profile = Rxn<dynamic>(); // Student or Tutor

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever<User?>(firebaseUser, _onAuthChanged);
    _onAuthChanged(_auth.currentUser);
  }

  Future<void> _onAuthChanged(User? user) async {
    isLoading.value = true;
    if (user == null) {
      profile.value = null;
      isLoading.value = false;
      return;
    }
    // Try students/{uid} first, then tutors/{uid}
    dynamic loaded; // Student or Tutor
    final studentDoc = await _db.collection('students').doc(user.uid).get();
    if (studentDoc.exists && studentDoc.data() != null) {
      // Ensure sid is present from document id
      loaded = Student.fromMap(studentDoc.data()!..['sid'] = user.uid);
    } else {
      final tutorDoc = await _db.collection('tutors').doc(user.uid).get();
      if (tutorDoc.exists && tutorDoc.data() != null) {
        // Ensure tid is present from document id
        loaded = Tutor.fromMap(tutorDoc.data()!..['tid'] = user.uid);
      }
    }
    profile.value = loaded;
    isLoading.value = false;
  }

  Future<String?> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? edu,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final isTutor = _collectionForRole(role) == 'tutors';
      final trimmedName = (name?.trim().isEmpty ?? true) ? null : name!.trim();
      final trimmedEdu = (edu?.trim().isEmpty ?? true) ? null : edu!.trim();
      final dynamic appUser = isTutor
          ? Tutor(
              tid: cred.user!.uid,
              email: email,
              name: trimmedName,
              edu: trimmedEdu,
            )
          : Student(
              sid: cred.user!.uid,
              email: email,
              name: trimmedName,
              edu: trimmedEdu,
            );
      final collection = _collectionForRole(role);
      // Use FirebaseAuth uid as document id
      await _db.collection(collection).doc(cred.user!.uid).set(appUser.toMap());
      await _onAuthChanged(cred.user);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in';

      // Delete profile document from Firestore
      try {
        final p = profile.value;
        if (p is Student) {
          await _db.collection('students').doc(p.sid).delete();
        } else if (p is Tutor) {
          await _db.collection('tutors').doc(p.tid).delete();
        } else {
          // Fallback: attempt both with uid
          await _db
              .collection('students')
              .doc(user.uid)
              .delete()
              .catchError((_) {});
          await _db
              .collection('tutors')
              .doc(user.uid)
              .delete()
              .catchError((_) {});
        }
      } catch (_) {
        // Ignore missing docs
      }

      // Delete Firebase Auth user (requires recent login)
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please re-login and try again to delete your account.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not signed in';
      final email = user.email;
      if (email == null) return 'No email associated with this account';

      // Reauthenticate with current password
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  String _collectionForRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == 'tutor' || r == 'tutors') return 'tutors';
    return 'students';
  }
}
