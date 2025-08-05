import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class NuevoTerrenoPage extends StatefulWidget {
  const NuevoTerrenoPage({super.key});

  @override
  State<NuevoTerrenoPage> createState() => _NuevoTerrenoPageState();
}

class _NuevoTerrenoPageState extends State<NuevoTerrenoPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  List<LatLng> puntos = [];
  String nombre = '';
  String descripcion = '';
  double? area;
  bool guardando = false;

  void _agregarPunto(LatLng punto) {
    setState(() {
      puntos.add(punto);
      area = _calcularArea(puntos);
    });
  }

  double _calcularArea(List<LatLng> pts) {
    if (pts.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % pts.length];
      sum += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }
    return (sum.abs() / 2) * 111139 * 111139;
  }

  Future<void> _guardarTerreno() async {
    if (!_formKey.currentState!.validate()) return;
    if (puntos.length < 3) {
      _mostrarMensaje('Debe marcar al menos 3 puntos', false);
      return;
    }

    setState(() => guardando = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _mostrarMensaje('Usuario no autenticado', false);
        return;
      }

      // Versión optimizada con timeout
      final saveFuture = supabase
          .from('terrenos')
          .insert({
            'user_id': user.id,
            'nombre': nombre,
            'descripcion': descripcion,
            'puntos': puntos
                .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                .toList(),
            'area': area,
          })
          .timeout(const Duration(seconds: 10));

      await saveFuture;

      _mostrarMensaje('Terreno guardado exitosamente', true);
      if (mounted) Navigator.pop(context, true);
    } on TimeoutException {
      _mostrarMensaje('Tiempo de espera agotado', false);
      debugPrint('Timeout al guardar terreno');
    } catch (e) {
      _mostrarMensaje('Error al guardar: ${e.toString()}', false);
      debugPrint('Error al guardar terreno: $e');
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  void _mostrarMensaje(String mensaje, bool exito) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Terreno'),
        actions: [
          if (puntos.isNotEmpty && !guardando)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                setState(() {
                  puntos.removeLast();
                  area = _calcularArea(puntos);
                });
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nombre del terreno',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() => nombre = value),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    maxLines: 2,
                    onChanged: (value) => setState(() => descripcion = value),
                  ),
                  const SizedBox(height: 16.0),
                  if (area != null && area! > 0)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.area_chart, color: Colors.blue),
                          const SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Área del terreno',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${(area! / 10000).toStringAsFixed(2)} hectáreas | ${area!.toStringAsFixed(2)} m²',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: puntos.isNotEmpty
                          ? puntos.first
                          : const LatLng(-2.2, -79.9),
                      initialZoom: 16.0,
                      onTap: (tapPos, latlng) => _agregarPunto(latlng),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.topografia_app',
                      ),
                      if (puntos.isNotEmpty)
                        MarkerLayer(
                          markers: puntos
                              .map(
                                (punto) => Marker(
                                  width: 40.0,
                                  height: 40.0,
                                  point: punto,
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40.0,
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
                              color: Colors.blue.withOpacity(0.3),
                              borderStrokeWidth: 3.0,
                              borderColor: Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (puntos.isNotEmpty)
                    Positioned(
                      top: 16.0,
                      right: 16.0,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4.0,
                            ),
                          ],
                        ),
                        child: Text(
                          'Puntos: ${puntos.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        guardando ? 'Guardando...' : 'Guardar Terreno',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor:
                            puntos.length > 2 && nombre.isNotEmpty && !guardando
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      onPressed:
                          puntos.length > 2 && nombre.isNotEmpty && !guardando
                          ? _guardarTerreno
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      backgroundColor: puntos.isNotEmpty && !guardando
                          ? Colors.red
                          : Colors.grey,
                    ),
                    onPressed: puntos.isNotEmpty && !guardando
                        ? () {
                            setState(() {
                              puntos.clear();
                              area = null;
                            });
                          }
                        : null,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
