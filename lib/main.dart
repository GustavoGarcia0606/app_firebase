import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
        ),
      
      ),
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
  final CollectionReference _list = FirebaseFirestore.instance.collection('tarefas');

  Future<void> _addList() async {
    if (_listControl.text.isNotEmpty) {
      try {
        await _list.add({
          "titulo": _listControl.text,
          "times": Timestamp.now(),
          "status": "pendente",
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
      appBar: AppBar(title: const Text('Minhas Tarefas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _listControl,
                    decoration: const InputDecoration(
                      labelText: 'Digite uma nova tarefa',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _addList,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
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

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            title: Text(
                              titulo,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Status: $status',
                              style: TextStyle(
                                color: status == 'concluída'
                                    ? Colors.green
                                    : status == 'em desenvolvimento'
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
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
