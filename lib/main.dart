import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/routes/app_routes.dart';
import 'package:task_notes_manager/global_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des bindings GetX
  Get.put(GlobalBinding());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Gestionnaire de Tâches & Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 2, centerTitle: true),
      ),
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      navigatorKey: Get.key,
      defaultTransition: Transition.cupertino,
    );
  }
}
