import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String? error;
  String? myId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = supabase.auth.currentUser;
      myId = user?.id;
      final res = await supabase.from('users').select();
      setState(() {
        users = List<Map<String, dynamic>>.from(
          res,
        ).where((u) => u['active'] == true && u['id'] != myId).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Compañeros topógrafos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Cargando topógrafos...'),
                ],
              ),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar los datos',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                  ),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final u = users[i];
                final isAdmin = u['role'] == 'admin';

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.amber[100] : Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin ? Icons.verified_user : Icons.person,
                        color: isAdmin ? Colors.amber[800] : Colors.blue[700],
                      ),
                    ),
                    title: Text(
                      u['username'] ?? u['email'] ?? u['id'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      isAdmin ? 'Administrador' : 'Topógrafo',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    trailing: isAdmin
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
