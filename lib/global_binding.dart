import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/note_controller.dart';
import 'package:task_notes_manager/controllers/admin_controller.dart';
import 'package:task_notes_manager/services/db_service.dart';

/// GlobalBinding - Initialise tous les controllers au démarrage de l'application
/// GetX Binding est un système d'injection de dépendances qui initialise les controllers
/// avant que les écrans ne soient chargés
class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    // Initialise le service de base de données (Singleton)
    Get.put(DatabaseService.instance, permanent: true);

    // Initialise le controller d'authentification
    // permanent: true → reste en mémoire même après navigation
    Get.put(AuthController(), permanent: true);

    // Initialise le controller des tâches
    Get.put(TaskController(), permanent: true);

    // Initialise le controller des notes
    Get.put(NoteController(), permanent: true);

    // Initialise le controller admin
    Get.put(AdminController(), permanent: true);

    print('✅ Tous les controllers ont été initialisés avec GlobalBinding');
  }
}

/// Explication du Binding dans GetX:
/// 
/// 1. **Pourquoi utiliser Bindings?**
///    - Initialisation précoce des controllers
///    - Gestion automatique de la mémoire (lazy loading)
///    - Injection de dépendances simplifiée
/// 
/// 2. **permanent: true**
///    - Le controller reste en mémoire même quand on navigue
///    - Utile pour les données globales (comme l'utilisateur connecté)
/// 
/// 3. **Get.put() vs Get.lazyPut()**
///    - Get.put(): Instance créée immédiatement
///    - Get.lazyPut(): Instance créée seulement quand elle est utilisée
/// 
/// 4. **Avantages:**
///    - Meilleure performance (controllers réutilisés)
///    - Moins de code répétitif
///    - Gestion automatique des dépendances