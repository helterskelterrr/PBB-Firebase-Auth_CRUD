import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore.dart';
import 'package:firebase/screen/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final tglController = TextEditingController();
  final labelController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  void openNoteBox({String? docId, String? title, String? content, String? tgl, String? label}) {
    titleController.text = title ?? '';
    contentController.text = content ?? '';
    tglController.text = tgl ?? '';
    labelController.text = label ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "Tambah Note" : "Edit Note"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: contentController, decoration: const InputDecoration(labelText: "Content")),
              TextField(controller: tglController, decoration: const InputDecoration(labelText: "Tanggal (tgl)")),
              TextField(controller: labelController, decoration: const InputDecoration(labelText: "Label")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (docId == null) {
                firestoreService.addNote(titleController.text, contentController.text, tglController.text, labelController.text);
              } else {
                firestoreService.updateNote(docId, titleController.text, contentController.text, tglController.text, labelController.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Notes CRUD - Nadip'),
              backgroundColor: Colors.blueGrey,
              actions: [
                IconButton(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => openNoteBox(),
              child: const Icon(Icons.add),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var notes = snapshot.data!.docs;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      var document = notes[index];
                      var data = document.data() as Map<String, dynamic>;
                      String id = document.id;

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(),
                              Expanded(
                                child: Text(
                                  data['content'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text("Tgl: ${data['tgl']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              Text("Label: ${data['label']}", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => openNoteBox(
                                      docId: id,
                                      title: data['title'],
                                      content: data['content'],
                                      tgl: data['tgl'],
                                      label: data['label'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => firestoreService.deleteNote(id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text("Belum ada catatan."));
                }
              },
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
