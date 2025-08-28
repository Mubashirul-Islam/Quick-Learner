import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import 'student_profile_view.dart';
import 'tutor_profile_view.dart';

class ProfileRouterView extends StatelessWidget {
  const ProfileRouterView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final u = auth.profile.value;
      if (u == null) return const Center(child: Text('No profile'));
      if (u is Tutor) return const TutorProfileView();
      if (u is Student) return const StudentProfileView();
      return const Center(child: Text('Unknown profile type'));
    });
  }
}
