import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_notes_manager/models/note_model.dart';
import 'package:task_notes_manager/services/note_service.dart';
import 'package:task_notes_manager/utils/helpers.dart';

class NoteController extends GetxController {
  final NoteService _noteService = NoteService(); // Service des notes
  final RxList<NoteModel> _notes =
      <NoteModel>[].obs; // Liste observable des notes

  List<NoteModel> get notes => _notes; // Getter pour toutes les notes

  // Charge les notes d'un utilisateur
  Future<void> loadUserNotes(int userId) async {
    try {
      Helpers.showLoading('Chargement des notes...');

      final userNotes = await _noteService.getNotesByUserId(userId);
      _notes.assignAll(userNotes);

      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors du chargement: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Crée une nouvelle note
  Future<bool> createNote(String title, String content, int userId) async {
    try {
      if (Helpers.isNullOrEmpty(title)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le titre est requis',
          backgroundColor: Colors.red,
        );
        return false;
      }

      if (Helpers.isNullOrEmpty(content)) {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Le contenu est requis',
          backgroundColor: Colors.red,
        );
        return false;
      }

      Helpers.showLoading('Création de la note...');

      final newNote = NoteModel(userId: userId, title: title, content: content);

      final noteId = await _noteService.createNote(newNote);

      Helpers.hideLoading();

      if (noteId != null) {
        newNote.id = noteId;
        _notes.insert(0, newNote); // Ajoute au début

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Note créée avec succès',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la création',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Met à jour une note
  Future<bool> updateNote(NoteModel note) async {
    try {
      Helpers.showLoading('Mise à jour en cours...');

      final success = await _noteService.updateNote(note);

      Helpers.hideLoading();

      if (success) {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = note; // Met à jour dans la liste
        }

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Note mise à jour',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la mise à jour',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Supprime une note
  Future<bool> deleteNote(int noteId) async {
    try {
      final confirm = await Helpers.showConfirmDialog(
        title: 'Confirmer la suppression',
        message: 'Voulez-vous vraiment supprimer cette note?',
      );

      if (confirm != true) return false;

      Helpers.showLoading('Suppression en cours...');

      final success = await _noteService.deleteNote(noteId);

      Helpers.hideLoading();

      if (success) {
        _notes.removeWhere((note) => note.id == noteId); // Supprime de la liste

        Helpers.showSnackbar(
          title: 'Succès',
          message: 'Note supprimée',
          backgroundColor: Colors.green,
        );
        return true;
      } else {
        Helpers.showSnackbar(
          title: 'Erreur',
          message: 'Erreur lors de la suppression',
          backgroundColor: Colors.red,
        );
        return false;
      }
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
      return false;
    }
  }

  // Recherche dans les notes
  Future<void> searchNotes(String keyword, int userId) async {
    try {
      if (Helpers.isNullOrEmpty(keyword)) {
        await loadUserNotes(
          userId,
        ); // Recharge toutes les notes si recherche vide
        return;
      }

      Helpers.showLoading('Recherche en cours...');

      final results = await _noteService.searchNotes(keyword, userId);
      _notes.assignAll(results);

      Helpers.hideLoading();
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(
        title: 'Erreur',
        message: 'Erreur lors de la recherche: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  // Récupère une note par ID
  NoteModel? getNoteById(int noteId) {
    try {
      return _notes.firstWhere((note) => note.id == noteId);
    } catch (e) {
      return null;
    }
  }

  // Compte le nombre de notes
  int get notesCount => _notes.length;

  // Vérifie si l'utilisateur a des notes
  bool hasNotes(int userId) {
    return _notes.any((note) => note.userId == userId);
  }

  // Vide la liste des notes
  void clearNotes() {
    _notes.clear();
  }
}
