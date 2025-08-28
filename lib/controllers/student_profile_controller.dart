import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class StudentProfileController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final Rxn<Student> student = Rxn<Student>();
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    final p = auth.profile.value;
    if (p is Student) student.value = p;
    ever(auth.profile, (u) {
      if (u is Student) {
        student.value = u;
      }
    });
  }

  Future<String?> save(Student updated) async {
    try {
      saving.value = true;
      await _db
          .collection('students')
          .doc(updated.sid)
          .set(updated.toMap(), SetOptions(merge: true));
      Get.find<AuthController>().profile.value = updated;
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      saving.value = false;
    }
  }
}
