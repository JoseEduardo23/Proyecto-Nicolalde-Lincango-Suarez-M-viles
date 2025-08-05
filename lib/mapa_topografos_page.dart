import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MapaTopografosPage extends StatefulWidget {
  const MapaTopografosPage({super.key});

  @override
  State<MapaTopografosPage> createState() => _MapaTopografosPageState();
}

class _MapaTopografosPageState extends State<MapaTopografosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ubicaciones = [];
  Map<String, String> userNames = {};
  bool loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _cargarUbicaciones(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarUbicaciones() async {
    setState(() => loading = true);
    final res = await supabase
        .from('ubicaciones')
        .select('user_id, latitud, longitud, timestamp')
        .order('timestamp', ascending: false);
    // Agrupar por user_id y tomar la última ubicación de cada usuario
    final Map<String, Map<String, dynamic>> latest = {};
    for (final row in res) {
      if (!latest.containsKey(row['user_id'])) {
        latest[row['user_id']] = row;
      }
    }
    // Obtener los usernames de los user_id únicos
    final userIds = latest.keys.toList();
    Map<String, String> usernamesMap = {};
    if (userIds.isNotEmpty) {
      final usersRes = await supabase
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);
      for (final u in usersRes) {
        usernamesMap[u['id']] = u['username'] ?? '';
      }
    }
    setState(() {
      ubicaciones = latest.values.toList();
      userNames = usernamesMap;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Topógrafos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarUbicaciones,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: ubicaciones.isNotEmpty
                    ? LatLng(
                        ubicaciones.first['latitud'],
                        ubicaciones.first['longitud'],
                      )
                    : LatLng(-2.2, -79.9), // Centro de Ecuador por defecto
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.topografia_app',
                ),
                MarkerLayer(
                  markers: ubicaciones
                      .map(
                        (u) => Marker(
                          width: 80,
                          height: 70,
                          point: LatLng(u['latitud'], u['longitud']),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.person_pin_circle,
                                color: Colors.red,
                                size: 40,
                              ),
                              Text(
                                userNames[u['user_id']] ??
                                    u['user_id'].toString().substring(0, 6),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}
