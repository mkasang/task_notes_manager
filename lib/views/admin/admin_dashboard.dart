import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/controllers/task_controller.dart';
import 'package:task_notes_manager/controllers/admin_controller.dart';
import 'package:task_notes_manager/models/user_model.dart';
import 'package:task_notes_manager/routes/app_routes.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final AuthController _authController = Get.find();
  final TaskController _taskController = Get.find();
  final AdminController _adminController = Get.find();

  late TabController _tabController; // Controller pour les onglets
  int _selectedIndex = 0; // Index de l'onglet sélectionné
  late AnimationController
  _animationController; // Controller pour les animations
  late Animation<double> _fadeAnimation; // Animation de fondu
  late Animation<Offset> _slideAnimation; // Animation de glissement

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 onglets
    _setupAnimations(); // Initialise les animations
    _loadData(); // Charge les données
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward(); // Démarre l'animation
  }

  Future<void> _loadData() async {
    // Charge toutes les données admin
    await _taskController.loadAllTasks();
    await _adminController.loadAllUsers();
  }

  void _refreshData() async {
    // Rafraîchit toutes les données
    await _loadData();
    Helpers.showSnackbar(
      title: 'Actualisé',
      message: 'Les données ont été rafraîchies',
      backgroundColor: Colors.green,
    );
  }

  void _logout() async {
    final confirm = await Helpers.showConfirmDialog(
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter?',
    );

    if (confirm == true) {
      _authController.logout();
    }
  }

  void _addUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: 'Nouvel Utilisateur',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty &&
                        emailController.text.isNotEmpty &&
                        passwordController.text.isNotEmpty) {
                      await _authController.createUser(
                        nameController.text,
                        emailController.text,
                        passwordController.text,
                      );
                      await _adminController.loadAllUsers();
                      Get.back();
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Panel Admin',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.1),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.refresh, color: Colors.blue),
          onPressed: _refreshData,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabs: const [
            Tab(text: 'Vue d\'ensemble', icon: Icon(Icons.dashboard)),
            Tab(text: 'Utilisateurs', icon: Icon(Icons.people)),
            Tab(text: 'Tâches', icon: Icon(Icons.task)),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedIndex == 0
            ? _buildOverviewTab()
            : _selectedIndex == 1
            ? _buildUsersTab()
            : _buildTasksTab(),
      ),
      floatingActionButton: _selectedIndex == 1
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FloatingActionButton(
                    onPressed: _addUser,
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    child: const Icon(Icons.person_add),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return Obx(() {
      final tasks = _taskController.tasks;
      final users = _adminController.users;

      final pendingTasks = tasks.where((t) => t.status == 'pending').length;
      final completedTasks = tasks.where((t) => t.status == 'done').length;
      final totalUsers = users.length;

      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques avec animations
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: child,
                    ),
                  );
                },
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Tâches en attente',
                      value: pendingTasks.toString(),
                      icon: Icons.access_time,
                      color: Colors.orange,
                      progress: tasks.isEmpty ? 0 : pendingTasks / tasks.length,
                    ),
                    _buildStatCard(
                      title: 'Tâches terminées',
                      value: completedTasks.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                      progress: tasks.isEmpty
                          ? 0
                          : completedTasks / tasks.length,
                    ),
                    _buildStatCard(
                      title: 'Utilisateurs',
                      value: totalUsers.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                      progress: 1.0,
                    ),
                    _buildStatCard(
                      title: 'Tâches totales',
                      value: tasks.length.toString(),
                      icon: Icons.task,
                      color: Colors.purple,
                      progress: 1.0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Dernières tâches
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(opacity: _fadeAnimation, child: child);
                },
                child: _buildRecentTasks(),
              ),

              const SizedBox(height: 32),

              // Derniers utilisateurs
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(opacity: _fadeAnimation, child: child);
                },
                child: _buildRecentUsers(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasks() {
    final recentTasks = _taskController.tasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dernières tâches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                  _tabController.index = 2;
                });
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.task, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucune tâche',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          )
        else
          ...recentTasks.map((task) {
            final user = _adminController.getUserById(task.userId);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(
                        task.status,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Helpers.getStatusIcon(task.status),
                      color: Helpers.getStatusColor(task.status),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        user?.name ?? 'Utilisateur inconnu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        Helpers.formatDate(task.createdAt!),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.comment, color: Colors.blue),
                    onPressed: () {
                      Get.toNamed(AppRoutes.taskComments, arguments: task);
                    },
                  ),
                  onTap: () {
                    Get.toNamed(AppRoutes.taskComments, arguments: task);
                  },
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildRecentUsers() {
    final recentUsers = _adminController.users.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Derniers utilisateurs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                  _tabController.index = 1;
                });
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentUsers.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.people, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucun utilisateur',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          )
        else
          ...recentUsers.map((user) {
            final userTasks = _taskController.getTasksByUserId(user.id!);
            final completedTasks = userTasks
                .where((t) => t.status == 'done')
                .length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: user.role == 'admin'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: user.role == 'admin' ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '${userTasks.length} tâches (${completedTasks} terminées)',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 18),
                        onPressed: () => _editUser(user),
                      ),
                      if (user.role == 'user')
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Obx(() {
      final users = _adminController.users;

      if (users.isEmpty) {
        return _buildEmptyState(
          icon: Icons.people,
          title: 'Aucun utilisateur',
          message: 'Ajoutez votre premier utilisateur',
          action: _addUser,
          actionText: 'Ajouter un utilisateur',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _adminController.loadAllUsers(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final userTasks = _taskController.getTasksByUserId(user.id!);
            final completedTasks = userTasks
                .where((t) => t.status == 'done')
                .length;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: user.role == 'admin'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      user.role == 'admin'
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: user.role == 'admin' ? Colors.red : Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              user.role == 'admin' ? 'Admin' : 'Utilisateur',
                              style: TextStyle(
                                fontSize: 10,
                                color: user.role == 'admin'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                            backgroundColor: user.role == 'admin'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            side: BorderSide.none,
                            shape: StadiumBorder(side: BorderSide.none),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              '${userTasks.length} tâches',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                            backgroundColor: Colors.green.withOpacity(0.1),
                          ),
                          if (userTasks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(
                                  '${completedTasks} terminées',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                ),
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUser(user),
                      ),
                      if (user.role == 'user')
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                    ],
                  ),
                  onTap: () => _editUser(user),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildTasksTab() {
    return Obx(() {
      final tasks = _taskController.tasks;

      if (tasks.isEmpty) {
        return _buildEmptyState(
          icon: Icons.task,
          title: 'Aucune tâche',
          message: 'Les utilisateurs n\'ont pas encore créé de tâches',
          action: _refreshData,
          actionText: 'Rafraîchir',
        );
      }

      return RefreshIndicator(
        onRefresh: _taskController.loadAllTasks,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final user = _adminController.getUserById(task.userId);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Helpers.getStatusColor(
                        task.status,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Helpers.getStatusIcon(task.status),
                      color: Helpers.getStatusColor(task.status),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        Helpers.truncateText(task.description, maxLength: 60),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: user?.role == 'admin'
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            child: Text(
                              user?.name[0] ?? '?',
                              style: TextStyle(
                                fontSize: 8,
                                color: user?.role == 'admin'
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.name ?? 'Utilisateur inconnu',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Helpers.formatDate(task.createdAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.comment, color: Colors.blue),
                    onPressed: () {
                      Get.toNamed(AppRoutes.taskComments, arguments: task);
                    },
                  ),
                  onTap: () {
                    Get.toNamed(AppRoutes.taskComments, arguments: task);
                  },
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback action,
    required String actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(actionText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: 'Modifier l\'utilisateur',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText:
                    'Nouveau mot de passe (laisser vide pour garder l\'actuel)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: user.role,
              decoration: InputDecoration(
                labelText: 'Rôle',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
              ],
              onChanged:
                  null, // On ne permet pas de changer le rôle pour l'instant
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final updatedUser = user.copyWith(
                      name: nameController.text,
                      email: emailController.text,
                      password: passwordController.text.isNotEmpty
                          ? passwordController.text
                          : user.password,
                    );
                    await _authController.updateUser(updatedUser);
                    await _adminController.loadAllUsers();
                    Get.back();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(UserModel user) async {
    final confirm = await Helpers.showConfirmDialog(
      title: 'Supprimer l\'utilisateur',
      message:
          'Êtes-vous sûr de vouloir supprimer ${user.name}? Cette action est irréversible.',
      confirmText: 'Supprimer',
    );

    if (confirm == true) {
      final success = await _authController.deleteUser(user.id!);
      if (success) {
        await _adminController.loadAllUsers();
      }
    }
  }
}
