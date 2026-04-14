import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');

  // Get current user UID dynamically
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // Create new note for a specific user
  Future<void> addNote(String title, String content, String tgl, String label) {
    return notes.add({
      'userId': userId,
      'title': title,
      'content': content,
      'tgl': tgl,
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  // Fetch all notes for the current user ONLY
  Stream<QuerySnapshot> getNotes(String? uid) {
    return notes
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update notes
  Future<void> updateNote(String id, String title, String content, String tgl, String label) {
    return notes.doc(id).update({
      'title': title,
      'content': content,
      'tgl': tgl,
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  // Delete notes
  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }
}
