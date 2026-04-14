import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore.dart';
import 'package:firebase/screen/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  void openNoteBox({String? docId, String? title, String? content, DateTime? tgl, String? label}) {
    titleController.text = title ?? '';
    contentController.text = content ?? '';
    tglController.text = tgl != null ? DateFormat('yyyy-MM-dd').format(tgl) : '';
    labelController.text = label ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(docId == null ? "Catatan Baru" : "Edit Catatan", 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Judul", alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Isi Catatan", alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tglController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Tanggal",
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      tglController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: "Label (opsional)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (docId == null) {
                firestoreService.addNote(
                  titleController.text,
                  contentController.text,
                  tglController.text,
                  labelController.text,
                );
              } else {
                firestoreService.updateNote(
                  docId,
                  titleController.text,
                  contentController.text,
                  tglController.text,
                  labelController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
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
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text('Catatan Saya', style: TextStyle(fontWeight: FontWeight.w600)),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              actions: [
                IconButton(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout_rounded),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => openNoteBox(),
              backgroundColor: Colors.black87,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getNotes(snapshot.data?.uid),
              builder: (context, firestoreSnapshot) {
                if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black87));
                }
                if (firestoreSnapshot.hasData && firestoreSnapshot.data!.docs.isNotEmpty) {
                  var notes = firestoreSnapshot.data!.docs;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      var data = notes[index].data() as Map<String, dynamic>;
                      String id = notes[index].id;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => openNoteBox(
                              docId: id,
                              title: data['title'],
                              content: data['content'],
                              tgl: data['tgl'] != null ? DateTime.tryParse(data['tgl']) : null,
                              label: data['label'],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => firestoreService.deleteNote(id),
                                        child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      data['content'] ?? '',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.3),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Tanggal minimalis
                                  Text(
                                    data['tgl'] ?? '',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  // Label sebagai text dengan style berbeda, bukan chip yang mencolok
                                  Text(
                                    "#${data['label'] ?? 'Umum'}",
                                    style: const TextStyle(
                                      fontSize: 11, 
                                      color: Colors.blueGrey, 
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text("Belum ada catatan", style: TextStyle(color: Colors.grey)));
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
