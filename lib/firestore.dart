import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');

  // Create new note
  Future<void> addNote(String title, String content, String tgl, String label) {
    return notes.add({
      'title': title,
      'content': content,
      'tgl': tgl,
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  // Fetch all notes
  Stream<QuerySnapshot> getNotes() {
    return notes.orderBy('createdAt', descending: true).snapshots();
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
