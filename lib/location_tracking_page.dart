import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LocationTrackingPage extends StatefulWidget {
  const LocationTrackingPage({super.key});

  @override
  State<LocationTrackingPage> createState() => _LocationTrackingPageState();
}

class _LocationTrackingPageState extends State<LocationTrackingPage> {
  Position? _currentPosition;
  String _status = '';
  StreamSubscription<Position>? _positionSubscription;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    setState(() {
      _status = 'Solicitando permisos...';
    });
    final granted = await LocationService.requestLocationPermission();
    if (!granted) {
      setState(() {
        _status = 'Permiso de ubicación denegado.';
      });
      return;
    }
    setState(() {
      _status = 'Obteniendo ubicación...';
    });
    _positionSubscription = LocationService.getPositionStream().listen((
      position,
    ) {
      setState(() {
        _currentPosition = position;
        _status = 'Ubicación actualizada';
      });
    });
  }

  Future<void> _guardarUbicacionEnSupabase() async {
    if (_currentPosition == null) return;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');
      await supabase.from('ubicaciones').insert({
        'user_id': user.id,
        'latitud': _currentPosition!.latitude,
        'longitud': _currentPosition!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      setState(() {
        _status = 'Ubicación guardada en Supabase';
      });
    } catch (e) {
      setState(() {
        _status = 'Error al guardar ubicación: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tracking en Tiempo Real',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Estado del tracking
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _status.contains('Activo')
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _status.contains('Activo')
                      ? Colors.green
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('Activo')
                      ? Colors.green[800]
                      : Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_currentPosition != null) ...[
              // Datos de ubicación
              _buildLocationCard(
                'Latitud',
                _currentPosition!.latitude.toStringAsFixed(6),
              ),
              const SizedBox(height: 12),
              _buildLocationCard(
                'Longitud',
                _currentPosition!.longitude.toStringAsFixed(6),
              ),
              const SizedBox(height: 12),
              _buildLocationCard(
                'Precisión',
                '${_currentPosition!.accuracy?.toStringAsFixed(1) ?? 'N/A'} metros',
              ),
              const SizedBox(height: 24),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _guardarUbicacionEnSupabase,
                  child: const Text(
                    'GUARDAR UBICACIÓN',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ] else ...[
              // Estado de carga
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Obteniendo ubicación...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para mostrar datos de ubicación
  Widget _buildLocationCard(String label, String value) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(value, style: const TextStyle(fontFamily: 'RobotoMono')),
          ],
        ),
      ),
    );
  }
}
