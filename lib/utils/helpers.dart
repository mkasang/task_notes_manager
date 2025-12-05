import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class Helpers {
  // Formatter de date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatDateOnly(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Hachage de mot de passe avec SHA-256
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validation d'email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Afficher un snackbar
  static void showSnackbar({
    required String title,
    required String message,
    Color backgroundColor = Colors.blue,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor.withOpacity(0.9),
      colorText: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  // Afficher un dialogue de confirmation
  static Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Afficher un dialogue de chargement
  static void showLoading([String? message]) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Chargement...'),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Cacher le dialogue de chargement
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Vérifier si une chaîne est vide ou null
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  // Capitaliser la première lettre
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Obtenir la couleur basée sur le statut
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case 'terminé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Obtenir l'icône basée sur le statut
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case 'terminé':
        return Icons.check_circle;
      case 'pending':
      case 'en attente':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  // Formater le texte pour l'affichage
  static String truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Vérifier si l'utilisateur est admin
  static bool isAdmin(String role) {
    return role.toLowerCase() == 'admin';
  }

  // Vérifier si l'utilisateur est user
  static bool isUser(String role) {
    return role.toLowerCase() == 'user';
  }

  // Générer un identifiant unique
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Valider les champs de formulaire
  static String? validateRequiredField(
    String? value, {
    String fieldName = 'Ce champ',
  }) {
    if (isNullOrEmpty(value)) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (isNullOrEmpty(value)) {
      return 'L\'email est requis';
    }
    if (!isValidEmail(value!)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (isNullOrEmpty(value)) {
      return 'Le mot de passe est requis';
    }
    if (value!.length < 3) {
      return 'Le mot de passe doit contenir au moins 3 caractères';
    }
    return null;
  }
}
