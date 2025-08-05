import 'users_list_page.dart';
import 'users_admin_page.dart';
import 'package:flutter/material.dart';
import 'location_tracking_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'mapa_topografos_page.dart';
import 'nuevo_terreno_page.dart';
import 'mapa_terrenos_page.dart';
import 'crear_terreno_desde_topografos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        role = null;
        loading = false;
      });
      return;
    }
    final res = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    setState(() {
      role = res != null ? res['role'] as String? : null;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Cargando tu perfil...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Compañeros',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersListPage()),
              ),
            ),
            if (role == 'admin')
              _buildFeatureCard(
                icon: Icons.admin_panel_settings,
                title: 'Administrar',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersAdminPage()),
                ),
              ),
            _buildFeatureCard(
              icon: Icons.location_on,
              title: 'Tracking',
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationTrackingPage()),
              ),
            ),
            _buildFeatureCard(
              icon: Icons.map,
              title: 'Topógrafos',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
              ),
            ),
            _buildFeatureCard(
              icon: Icons.landscape,
              title: 'Nuevo Terreno',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NuevoTerrenoPage()),
              ),
            ),
            _buildFeatureCard(
              icon: Icons.add_location,
              title: 'Crear Terreno',
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrearTerrenoDesdeTopografosPage(),
                ),
              ),
            ),
            _buildFeatureCard(
              icon: Icons.map_outlined,
              title: 'Terrenos',
              color: Colors.brown,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapaTerrenosPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para tarjetas de características
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
