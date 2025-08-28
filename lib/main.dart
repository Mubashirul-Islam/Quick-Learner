import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/home/home_view.dart';
import 'views/home/post_query_view.dart';
import 'views/home/query_responses_view.dart';
import 'views/home/notifications_view.dart';
import 'controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quick Learner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      getPages: [
        GetPage(name: '/login', page: LoginView.new),
        GetPage(name: '/register', page: RegisterView.new),
        GetPage(name: '/home', page: HomeView.new),
        GetPage(name: '/post-query', page: PostQueryView.new),
        GetPage(name: '/query-responses', page: QueryResponsesView.new),
        GetPage(name: '/notifications', page: NotificationsView.new),
      ],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends GetWidget<AuthController> {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return controller.firebaseUser.value != null
          ? const HomeView()
          : const LoginView();
    });
  }
}
