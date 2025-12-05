import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/note_controller.dart';
import 'package:task_notes_manager/controllers/admin_controller.dart';
import 'package:task_notes_manager/services/db_service.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    // Initialiser DatabaseService
    Get.put<DatabaseService>(DatabaseService(), permanent: true);

    // Initialiser les controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<TaskController>(TaskController(), permanent: true);
    Get.put<NoteController>(NoteController(), permanent: true);
    Get.put<AdminController>(AdminController(), permanent: true);

    print('✅ Tous les services et controllers ont été initialisés');
  }
}
