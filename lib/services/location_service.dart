import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class LocationService {
  // ✅ Obtener ubicación actual del usuario - CON MANEJO MEJORADO DE ERRORES
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Verificar y solicitar permisos
      final permissionStatus = await _checkLocationPermission();
      if (!permissionStatus) {
        throw 'Permisos de ubicación denegados';
      }

      // Obtener posición actual
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Usar medium para mejor compatibilidad
          distanceFilter: 10,
        ),
      );

      AppLogger.d('📍 Coordenadas obtenidas: ${position.latitude}, ${position.longitude}');

      // ✅ INTENTAR OBTENER DIRECCIÓN CON MANEJO ROBUSTO DE ERRORES
      String address = 'Ubicación no disponible';
      String city = 'Holguín';

      try {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark placemark = placemarks.first;
          address = _formatAddress(placemark);
          city = placemark.locality ?? 'Holguín';
          AppLogger.d('✅ Dirección obtenida: $address');
        } else {
          AppLogger.w('⚠️ No se encontraron placemarks para las coordenadas');
          address = 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        // ✅ MANEJAR ERRORES DE GEOCODING ESPECÍFICAMENTE
        AppLogger.w('⚠️ Error en geocoding, usando coordenadas: $e');
        address = 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      return <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'city': city,
        'state': '',
        'country': '',
        'postalCode': '',
        'success': true,
      };

    } catch (e) {
      AppLogger.e('❌ Error obteniendo ubicación', e);
      return <String, dynamic>{
        'success': false,
        'error': 'No se pudo obtener la ubicación: $e',
      };
    }
  }

  // ✅ Verificar y solicitar permisos de ubicación
  static Future<bool> _checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('Servicios de ubicación deshabilitados');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.w('Permisos de ubicación denegados permanentemente');
        return false;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('Usuario denegó los permisos de ubicación');
          return false;
        }
      }

      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;

    } catch (e) {
      AppLogger.e('Error verificando permisos de ubicación', e);
      return false;
    }
  }

  // ✅ Formatear dirección legible
  static String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }

    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }

    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }

    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Ubicación no disponible';
  }

  // ✅ Obtener solo coordenadas (sin geocoding)
  static Future<Map<String, dynamic>> getCoordinatesOnly() async {
    try {
      final permissionStatus = await _checkLocationPermission();
      if (!permissionStatus) {
        throw 'Permisos de ubicación denegados';
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      );

      return <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'city': 'Holguín',
        'success': true,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo coordenadas', e);
      return <String, dynamic>{
        'success': false,
        'error': 'No se pudo obtener la ubicación: $e',
      };
    }
  }

  // ✅ Calcular distancia entre dos puntos
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    try {
      return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    } catch (e) {
      AppLogger.e('Error calculando distancia', e);
      return 0.0;
    }
  }

  // ✅ Obtener dirección desde coordenadas (con manejo de errores)
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }
      return 'Ubicación: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      AppLogger.w('Error en geocoding, retornando coordenadas: $e');
      return 'Ubicación: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  // ✅ Verificar si los servicios de ubicación están habilitados
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      AppLogger.e('Error verificando servicios de ubicación', e);
      return false;
    }
  }

  // ✅ Obtener última ubicación conocida
  static Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      final Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          'success': true,
        };
      }
      return null;
    } catch (e) {
      AppLogger.e('Error obteniendo última ubicación conocida', e);
      return null;
    }
  }
}