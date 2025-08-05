import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

double calcularArea(List<LatLng> pts) {
  if (pts.length < 3) return 0.0;
  double sum = 0.0;
  for (int i = 0; i < pts.length; i++) {
    final p1 = pts[i];
    final p2 = pts[(i + 1) % pts.length];
    sum += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
  }
  return (sum.abs() / 2) * 111139 * 111139 / 1e6;
}

class MapaTerrenosPage extends StatefulWidget {
  const MapaTerrenosPage({super.key});

  @override
  State<MapaTerrenosPage> createState() => _MapaTerrenosPageState();
}

class _MapaTerrenosPageState extends State<MapaTerrenosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> terrenos = [];
  bool cargando = true;
  int? terrenoSeleccionado;
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    _cargarTerrenos();
  }

  Future<void> _cargarTerrenos() async {
    final res = await supabase.from('terrenos').select();
    setState(() {
      terrenos = List<Map<String, dynamic>>.from(res);
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terrenos guardados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : terrenos.isEmpty
          ? const Center(
              child: Text(
                'No hay terrenos guardados',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter:
                          terrenos.isNotEmpty &&
                              terrenos.first['puntos'] != null &&
                              terrenos.first['puntos'].isNotEmpty
                          ? LatLng(
                              terrenos.first['puntos'][0]['lat'],
                              terrenos.first['puntos'][0]['lng'],
                            )
                          : LatLng(-2.2, -79.9),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.topografia_app',
                      ),
                      ...terrenos.asMap().entries.map((entry) {
                        final i = entry.key;
                        final terreno = entry.value;
                        final puntos = (terreno['puntos'] as List)
                            .map(
                              (p) => LatLng(
                                p['lat'] as double,
                                p['lng'] as double,
                              ),
                            )
                            .toList();
                        return PolygonLayer(
                          polygons: [
                            Polygon(
                              points: puntos,
                              color: i == terrenoSeleccionado
                                  ? Colors.orange.withOpacity(0.5)
                                  : Colors.green.withOpacity(0.3),
                              borderStrokeWidth: i == terrenoSeleccionado
                                  ? 4
                                  : 3,
                              borderColor: i == terrenoSeleccionado
                                  ? Colors.orange
                                  : Colors.green[700]!,
                            ),
                          ],
                        );
                      }).toList(),
                      ...terrenos.expand((terreno) {
                        final puntos = (terreno['puntos'] as List)
                            .map(
                              (p) => LatLng(
                                p['lat'] as double,
                                p['lng'] as double,
                              ),
                            )
                            .toList();
                        return puntos.map(
                          (p) => MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: p,
                                child: Icon(
                                  Icons.location_on,
                                  color:
                                      terrenos.indexOf(terreno) ==
                                          terrenoSeleccionado
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Container(
                  height: 180,
                  padding: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    itemCount: terrenos.length,
                    itemBuilder: (context, i) {
                      final t = terrenos[i];
                      final area =
                          t['area'] ??
                          calcularArea(
                            (t['puntos'] as List)
                                .map(
                                  (p) => LatLng(
                                    p['lat'] as double,
                                    p['lng'] as double,
                                  ),
                                )
                                .toList(),
                          );
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: i == terrenoSeleccionado
                            ? Colors.orange.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          title: Text(
                            t['nombre'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Área: ${area.toStringAsFixed(2)} m²'),
                              if (t['descripcion'] != null)
                                Text(t['descripcion']!),
                            ],
                          ),
                          onTap: () {
                            setState(() => terrenoSeleccionado = i);
                            final puntos = (t['puntos'] as List)
                                .map(
                                  (p) => LatLng(
                                    p['lat'] as double,
                                    p['lng'] as double,
                                  ),
                                )
                                .toList();
                            if (puntos.isNotEmpty) {
                              mapController.move(puntos.first, 17);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
