import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';

class CrearTerrenoDesdeTopografosPage extends StatefulWidget {
  const CrearTerrenoDesdeTopografosPage({super.key});

  @override
  State<CrearTerrenoDesdeTopografosPage> createState() =>
      _CrearTerrenoDesdeTopografosPageState();
}

class _CrearTerrenoDesdeTopografosPageState
    extends State<CrearTerrenoDesdeTopografosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ubicaciones = [];
  Map<String, String> userNames = {};
  bool loading = true;
  String nombre = '';
  String descripcion = '';
  double? area;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  Future<void> _cargarUbicaciones() async {
    setState(() => loading = true);
    final res = await supabase
        .from('ubicaciones')
        .select('user_id, latitud, longitud, timestamp')
        .order('timestamp', ascending: false);
    final Map<String, Map<String, dynamic>> latest = {};
    for (final row in res) {
      if (!latest.containsKey(row['user_id'])) {
        latest[row['user_id']] = row;
      }
    }
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
    _calcularArea();
  }

  void _calcularArea() {
    if (ubicaciones.length < 3) {
      setState(() => area = 0);
      return;
    }
    final puntos = ubicaciones
        .map((u) => LatLng(u['latitud'], u['longitud']))
        .toList();
    double sum = 0.0;
    for (int i = 0; i < puntos.length; i++) {
      final p1 = puntos[i];
      final p2 = puntos[(i + 1) % puntos.length];
      sum += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    setState(() {
      area = (sum.abs() / 2) * 111139 * 111139; //m2
    });
  }

  Future<void> _guardarTerreno() async {
    if (ubicaciones.length < 3 || nombre.isEmpty) return;
    setState(() => guardando = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final puntos = ubicaciones
        .map((u) => {'lat': u['latitud'], 'lng': u['longitud']})
        .toList();
    await supabase.from('terrenos').insert({
      'user_id': user.id,
      'nombre': nombre,
      'descripcion': descripcion,
      'puntos': puntos,
      'area': area,
    });
    setState(() => guardando = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = ubicaciones
        .map((u) => LatLng(u['latitud'], u['longitud']))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Terreno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarUbicaciones,
            tooltip: 'Actualizar ubicaciones',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Cargando topógrafos...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Sección de formulario
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Nombre del terreno',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.landscape),
                        ),
                        onChanged: (v) => setState(() => nombre = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Descripción (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        onChanged: (v) => setState(() => descripcion = v),
                      ),
                      if (area != null && area! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.area_chart, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Área: ${area!.toStringAsFixed(2)} km²',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: puntos.isNotEmpty
                              ? puntos.first
                              : const LatLng(-2.2, -79.9),
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.topografia_app',
                          ),
                          if (puntos.isNotEmpty)
                            MarkerLayer(
                              markers: ubicaciones
                                  .map(
                                    (u) => Marker(
                                      width: 60,
                                      height: 60,
                                      point: LatLng(
                                        u['latitud'],
                                        u['longitud'],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.location_pin,
                                            color: Colors.red,
                                            size: 32,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              userNames[u['user_id']] ??
                                                  u['user_id']
                                                      .toString()
                                                      .substring(0, 6),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          if (puntos.length > 2)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: puntos,
                                  color: Colors.green.withOpacity(0.3),
                                  borderStrokeWidth: 3,
                                  borderColor: Colors.green[700]!,
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (puntos.length > 2)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              '${puntos.length} puntos seleccionados',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Botón de acción
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: guardando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        guardando ? 'Guardando...' : 'Guardar Terreno',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          puntos.length > 2 && nombre.isNotEmpty && !guardando
                          ? _guardarTerreno
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
