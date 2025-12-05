import 'package:get/get.dart';
import 'package:task_notes_manager/views/auth/login_view.dart';
import 'package:task_notes_manager/views/admin/admin_dashboard.dart';
import 'package:task_notes_manager/views/admin/manage_users.dart';
import 'package:task_notes_manager/views/admin/task_comments_view.dart';
import 'package:task_notes_manager/views/user/user_dashboard.dart';
import 'package:task_notes_manager/views/user/task_list_view.dart';
import 'package:task_notes_manager/views/user/notes_view.dart';

class AppRoutes {
  static const String login = '/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String manageUsers = '/admin/users';
  static const String taskComments = '/admin/task/:id';
  static const String userDashboard = '/user/dashboard';
  static const String userTasks = '/user/tasks';
  static const String userNotes = '/user/notes';

  static List<GetPage> routes = [
    GetPage(
      name: login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: adminDashboard,
      page: () => const AdminDashboard(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: manageUsers,
      page: () => const ManageUsersView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: taskComments,
      page: () => const TaskCommentsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: userDashboard,
      page: () => const UserDashboard(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: userTasks,
      page: () => const TaskListView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: userNotes,
      page: () => const NotesView(),
      transition: Transition.rightToLeft,
    ),
  ];
}
