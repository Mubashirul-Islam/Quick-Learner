import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class TutorProfileController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final Rxn<Tutor> tutor = Rxn<Tutor>();
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    final p = auth.profile.value;
    if (p is Tutor) tutor.value = p;
    ever(auth.profile, (u) {
      if (u is Tutor) {
        tutor.value = u;
      }
    });
  }

  Future<String?> save(Tutor updated) async {
    try {
      saving.value = true;
      await _db
          .collection('tutors')
          .doc(updated.tid)
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
