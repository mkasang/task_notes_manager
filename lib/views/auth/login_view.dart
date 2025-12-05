import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:task_notes_manager/controllers/auth_controller.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  final AuthController _authController =
      Get.find(); // Récupère le controller d'authentification
  final _formKey = GlobalKey<FormState>(); // Clé pour le formulaire
  final _emailController = TextEditingController(); // Controller pour l'email
  final _passwordController =
      TextEditingController(); // Controller pour le mot de passe

  bool _isPasswordVisible = false; // État pour afficher/cacher le mot de passe
  bool _isLoading = false; // État pour le chargement
  late AnimationController
  _animationController; // Controller pour les animations
  late Animation<double> _fadeAnimation; // Animation de fondu
  late Animation<Offset> _slideAnimation; // Animation de glissement

  @override
  void initState() {
    super.initState();
    _setupAnimations(); // Initialise les animations
    _prefillAdminCredentials(); // Pré-remplit les identifiants admin pour les tests
  }

  void _setupAnimations() {
    // Controller d'animation avec durée de 800ms
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animation de fondu (opacité de 0 à 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animation de glissement (de bas en haut)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Démarre l'animation après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  void _prefillAdminCredentials() {
    // Pré-remplit avec les identifiants admin pour faciliter les tests
    _emailController.text = 'admin@app.com';
    _passwordController.text = 'admin';
  }

  @override
  void dispose() {
    _animationController.dispose(); // Nettoie le controller d'animation
    _emailController.dispose(); // Nettoie le controller d'email
    _passwordController.dispose(); // Nettoie le controller de mot de passe
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Valide le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Active l'indicateur de chargement
    });

    try {
      // Appelle la méthode de connexion du controller
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success) {
        // Efface le mot de passe en cas d'erreur
        _passwordController.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Désactive l'indicateur de chargement
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible; // Inverse l'état de visibilité
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Fond gris clair
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: _slideAnimation.value * 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Logo et titre avec animation
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.elasticOut,
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.task_alt,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Titre principal avec animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Connectez-vous à votre compte',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Champ email avec animation
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildEmailField(),
                        ),

                        const SizedBox(height: 20),

                        // Champ mot de passe avec animation
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildPasswordField(),
                        ),

                        const SizedBox(height: 30),

                        // Bouton de connexion avec animation
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.5,
                              1.0,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: _buildLoginButton(),
                        ),

                        const SizedBox(height: 30),

                        // Informations de test
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue[700],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Informations de test',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Admin: admin@app.com / admin\nUser: Créez un utilisateur depuis le panel admin',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Entrez votre email',
        prefixIcon: Icon(Icons.email, color: Colors.blue[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      style: TextStyle(color: Colors.grey[800]),
      validator: (value) =>
          Helpers.validateEmail(value), // Validation de l'email
      onFieldSubmitted: (_) =>
          FocusScope.of(context).nextFocus(), // Passe au champ suivant
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        hintText: 'Entrez votre mot de passe',
        prefixIcon: Icon(Icons.lock, color: Colors.blue[400]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: _togglePasswordVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        // focusedBorder: OutlineInputDecoration(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: const BorderSide(color: Colors.blue, width: 2),
        // ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      style: TextStyle(color: Colors.grey[800]),
      validator: (value) =>
          Helpers.validatePassword(value), // Validation du mot de passe
      onFieldSubmitted: (_) => _handleLogin(), // Soumet le formulaire
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: Colors.blue.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }
}
