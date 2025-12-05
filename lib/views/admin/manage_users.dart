import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/controllers/admin_controller.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find();
  final AdminController _adminController = Get.find();

  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  String _searchQuery = '';
  List<int> _selectedUsers = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _setupAnimations();
    _loadUsers();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  Future<void> _loadUsers() async {
    await _adminController.loadAllUsers(_authController);
  }

  List<dynamic> _getFilteredUsers() {
    final users = _adminController.users;

    if (_searchQuery.isEmpty) {
      return users;
    }

    return users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }

      if (_selectedUsers.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllUsers() {
    final filteredUsers = _getFilteredUsers();
    setState(() {
      // CORRECTION: Convertir explicitement en List<int>
      _selectedUsers = filteredUsers.map<int>((user) => user.id!).toList();
    });
  }

  void _deselectAllUsers() {
    setState(() {
      _selectedUsers.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedUsers() async {
    if (_selectedUsers.isEmpty) return;

    final confirm = await Helpers.showConfirmDialog(
      title: 'Supprimer les utilisateurs',
      message:
          'Êtes-vous sûr de vouloir supprimer ${_selectedUsers.length} utilisateur(s)?',
      confirmText: 'Supprimer',
    );

    if (confirm == true) {
      Helpers.showLoading('Suppression en cours...');

      bool allDeleted = true;
      for (final userId in _selectedUsers) {
        final success = await _authController.deleteUser(userId);
        if (!success) {
          allDeleted = false;
        }
      }

      Helpers.hideLoading();

      if (allDeleted) {
        await _loadUsers();
        _deselectAllUsers();
        Helpers.showSnackbar(
          title: 'Succès',
          message: '${_selectedUsers.length} utilisateur(s) supprimé(s)',
          backgroundColor: Colors.green,
        );
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Certains utilisateurs n\'ont pas pu être supprimés',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _addNewUser() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: 'Nouvel Utilisateur',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ScaleTransition(scale: _scaleAnimation, child: child);
              },
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person, color: Colors.blue[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blue[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
                      final success = await _authController.createUser(
                        nameController.text,
                        emailController.text,
                        passwordController.text,
                      );

                      if (success) {
                        await _loadUsers();
                        Get.back();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Créer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editUser(dynamic user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: 'Modifier l\'Utilisateur',
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
                labelText: 'Nouveau mot de passe (laisser vide pour garder)',
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
                    final updatedUser = user.copyWith(
                      name: nameController.text,
                      email: emailController.text,
                      password: passwordController.text.isNotEmpty
                          ? passwordController.text
                          : user.password,
                    );

                    final success = await _authController.updateUser(
                      updatedUser,
                    );
                    if (success) {
                      await _loadUsers();
                      Get.back();
                    }
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

  void _showUserDetails(dynamic user) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 60,
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
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user.email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailItem(
              icon: Icons.assignment_ind,
              label: 'Rôle',
              value: user.role == 'admin' ? 'Administrateur' : 'Utilisateur',
              color: user.role == 'admin' ? Colors.red : Colors.blue,
            ),
            _buildDetailItem(
              icon: Icons.calendar_today,
              label: 'Date de création',
              value: Helpers.formatDate(user.createdAt!),
              color: Colors.green,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _editUser(user);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                ),
                if (user.role == 'user') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        final confirm = await Helpers.showConfirmDialog(
                          title: 'Supprimer l\'utilisateur',
                          message:
                              'Êtes-vous sûr de vouloir supprimer ${user.name}?',
                          confirmText: 'Supprimer',
                        );

                        if (confirm == true) {
                          final success = await _authController.deleteUser(
                            user.id!,
                          );
                          if (success) {
                            await _loadUsers();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, size: 18),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSelectionMode
              ? Text(
                  '${_selectedUsers.length} sélectionné(s)',
                  style: const TextStyle(fontSize: 16),
                )
              : const Text('Gestion des Utilisateurs'),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAllUsers,
              tooltip: 'Tout sélectionner',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedUsers,
              tooltip: 'Supprimer la sélection',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _deselectAllUsers,
              tooltip: 'Annuler la sélection',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Focus sur la recherche
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(Duration.zero, () {
                  FocusScope.of(context).requestFocus(FocusNode());
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Mode sélection',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: SlideTransition(
              position: _slideAnimation,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Liste des utilisateurs
          Expanded(
            child: Obx(() {
              final filteredUsers = _getFilteredUsers();

              if (filteredUsers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _loadUsers,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isSelected = _selectedUsers.contains(user.id);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(color: Colors.blue, width: 2)
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : user.role == 'admin'
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                              ),
                              child: Icon(
                                user.role == 'admin'
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: isSelected
                                    ? Colors.blue
                                    : user.role == 'admin'
                                    ? Colors.red
                                    : Colors.blue,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    user.role == 'admin'
                                        ? 'Admin'
                                        : 'Utilisateur',
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
                                ),
                              ],
                            ),
                            trailing: _isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (value) =>
                                        _toggleUserSelection(user.id!),
                                    activeColor: Colors.blue,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.visibility,
                                          color: Colors.blue[400],
                                        ),
                                        onPressed: () => _showUserDetails(user),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue[400],
                                        ),
                                        onPressed: () => _editUser(user),
                                      ),
                                    ],
                                  ),
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleUserSelection(user.id!);
                              } else {
                                _showUserDetails(user);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _toggleSelectionMode();
                                _toggleUserSelection(user.id!);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FloatingActionButton(
                    onPressed: _addNewUser,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'Aucun utilisateur' : 'Aucun résultat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Ajoutez votre premier utilisateur'
                : 'Essayez avec d\'autres termes',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: _addNewUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Ajouter un utilisateur'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
