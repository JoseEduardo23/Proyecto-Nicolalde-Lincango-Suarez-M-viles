import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await supabase.from('users').select();
      setState(() {
        users = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    await supabase.from('users').update({'role': newRole}).eq('id', userId);
    _loadUsers();
  }

  Future<void> _toggleActive(String userId, bool active) async {
    await supabase.from('users').update({'active': active}).eq('id', userId);
    _loadUsers();
  }

  Future<void> _deleteUser(String userId) async {
    await supabase.from('users').delete().eq('id', userId);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return Card(
                      child: ListTile(
                        title: Text(u['username'] ?? u['email'] ?? u['id']),
                        subtitle: Text('Rol: ${u['role']}\nActivo: ${u['active']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: u['role'],
                              items: const [
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'topografo', child: Text('Topógrafo')),
                              ],
                              onChanged: (v) {
                                if (v != null) _changeRole(u['id'], v);
                              },
                            ),
                            Switch(
                              value: u['active'] ?? true,
                              onChanged: (v) => _toggleActive(u['id'], v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(u['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
