import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //garante que tudo esteja pronto ao carregar
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ListPage(),
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final TextEditingController _listControl = TextEditingController();
  final CollectionReference _list = FirebaseFirestore.instance.collection(
    'tarefas',
  );

  Future<void> _addList() async {
  if (_listControl.text.isNotEmpty) {
    try {
      await _list.add({
        "titulo": _listControl.text,
        "times": Timestamp.now(),
        "status": "pendente", // novo campo
      });
      _listControl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar: $e')),
      );
    }
  }
}
Future<void> _deleteTask(String id) async {
    try {
      await _list.doc(id).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar tarefa: $e')),
      );
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _list.doc(id).update({'status': newStatus});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _listControl,
                    decoration: const InputDecoration(labelText: 'Nova Tarefa'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addList),
              ],
            ),
          ),
           Expanded(
            child: StreamBuilder(
              stream: _list.orderBy('times', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                      final String titulo = documentSnapshot['titulo'];
                      final String status = documentSnapshot['status'] ?? 'indefinido';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          title: Text(titulo),
                          subtitle: Text('Status: $status'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTask(documentSnapshot.id),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (String newStatus) {
                                  _updateStatus(documentSnapshot.id, newStatus);
                                },
                                itemBuilder: (BuildContext context) => const [
                                  PopupMenuItem(value: 'pendente', child: Text('Pendente')),
                                  PopupMenuItem(value: 'em desenvolvimento', child: Text('Em desenvolvimento')),
                                  PopupMenuItem(value: 'concluída', child: Text('Concluída')),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}