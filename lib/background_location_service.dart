import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
  service.startService();
}

void onStart(ServiceInstance service) async {
  // No es necesario DartPluginRegistrant.ensureInitialized() en Flutter 3.8+
  final supabase = Supabase.instance.client;
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Topografía App',
        content: 'Tracking de ubicación en segundo plano',
      );
    }
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('ubicaciones').insert({
          'user_id': user.id,
          'latitud': position.latitude,
          'longitud': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  });
}
