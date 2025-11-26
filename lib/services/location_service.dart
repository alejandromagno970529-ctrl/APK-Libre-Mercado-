// lib/services/location_service.dart - VERSIÓN CORREGIDA
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:libre_mercado_final__app/utils/logger.dart';

class LocationService {
  // Cache para ubicaciones
  static Map<String, dynamic>? _cachedLocation;
  static DateTime? _lastLocationFetch;
  
  // ✅ Obtener ubicación actual del usuario - CON CACHÉ Y OPTIMIZACIÓN
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    // Verificar caché (válido por 30 segundos)
    if (_cachedLocation != null && _lastLocationFetch != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastLocationFetch!);
      if (difference.inSeconds < 30) {
        AppLogger.d('📍 Usando ubicación en caché');
        return _cachedLocation!;
      }
    }

    try {
      // Verificar y solicitar permisos
      final permissionStatus = await _checkLocationPermission();
      if (!permissionStatus) {
        throw 'Permisos de ubicación denegados';
      }

      // Obtener posición actual con timeout
      final Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.medium,  // ✅ CORRECCIÓN
).timeout(const Duration(seconds: 15));
      AppLogger.d('📍 Coordenadas obtenidas: ${position.latitude}, ${position.longitude}');

      // ✅ OBTENER DIRECCIÓN DE FORMA ASÍNCRONA (no bloqueante)
      String address = 'Ubicación no disponible';
      String city = 'Holguín';

      // Iniciar geocoding pero no esperar si tarda mucho
      final geocodingFuture = _getAddressFromPosition(position);
      
      // Usar timeout para geocoding
      try {
        final addressData = await geocodingFuture.timeout(const Duration(seconds: 5));
        address = addressData['address'] ?? 'Ubicación no disponible';
        city = addressData['city'] ?? 'Holguín';
        AppLogger.d('✅ Dirección obtenida: $address');
      } catch (e) {
        AppLogger.w('⚠️ Timeout en geocoding, usando coordenadas: $e');
        address = 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'city': city,
        'state': '',
        'country': '',
        'postalCode': '',
        'success': true,
      };

      // Guardar en caché
      _cachedLocation = locationData;
      _lastLocationFetch = DateTime.now();

      return locationData;

    } catch (e) {
      AppLogger.e('❌ Error obteniendo ubicación', e);
      
      // Intentar usar última ubicación conocida
      final lastKnown = await getLastKnownLocation();
      if (lastKnown != null) {
        AppLogger.d('📍 Usando última ubicación conocida');
        return lastKnown;
      }
      
      return <String, dynamic>{
        'success': false,
        'error': 'No se pudo obtener la ubicación: $e',
      };
    }
  }

  // ✅ Obtener dirección desde posición
  static Future<Map<String, String>> _getAddressFromPosition(Position position) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark placemark = placemarks.first;
        return {
          'address': _formatAddress(placemark),
          'city': placemark.locality ?? 'Holguín', // ✅ CORREGIDO: manejo de null
        };
      } else {
        AppLogger.w('⚠️ No se encontraron placemarks para las coordenadas');
        return {
          'address': 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          'city': 'Holguín',
        };
      }
    } catch (e) {
      AppLogger.w('⚠️ Error en geocoding, usando coordenadas: $e');
      return {
        'address': 'Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'city': 'Holguín',
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

  // ✅ Obtener solo coordenadas (sin geocoding) - OPTIMIZADO
  static Future<Map<String, dynamic>> getCoordinatesOnly() async {
    // Verificar caché
    if (_cachedLocation != null && _lastLocationFetch != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastLocationFetch!);
      if (difference.inSeconds < 30) {
        AppLogger.d('📍 Usando coordenadas en caché');
        return _cachedLocation!;
      }
    }

    try {
      final permissionStatus = await _checkLocationPermission();
      if (!permissionStatus) {
        throw 'Permisos de ubicación denegados';
      }

      final Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.medium,  // ✅ CORRECCIÓN
).timeout(const Duration(seconds: 10));

      final locationData = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'city': 'Holguín',
        'success': true,
      };

      // Guardar en caché
      _cachedLocation = locationData;
      _lastLocationFetch = DateTime.now();

      return locationData;
    } catch (e) {
      AppLogger.e('Error obteniendo coordenadas', e);
      
      // Intentar última ubicación conocida
      final lastKnown = await getLastKnownLocation();
      if (lastKnown != null) {
        AppLogger.d('📍 Usando última ubicación conocida como fallback');
        return lastKnown;
      }
      
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

  // ✅ Obtener última ubicación conocida - OPTIMIZADO
  static Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      final Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        final locationData = <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          'success': true,
        };
        
        // Actualizar caché
        _cachedLocation = locationData;
        _lastLocationFetch = DateTime.now();
        
        return locationData;
      }
      return null;
    } catch (e) {
      AppLogger.e('Error obteniendo última ubicación conocida', e);
      return null;
    }
  }

  // ✅ Limpiar caché (útil para forzar nueva obtención)
  static void clearCache() {
    _cachedLocation = null;
    _lastLocationFetch = null;
    AppLogger.d('🗑️ Caché de ubicación limpiado');
  }

  // ✅ Verificar si hay caché válido
  static bool hasValidCache() {
    if (_cachedLocation == null || _lastLocationFetch == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastLocationFetch!);
    return difference.inSeconds < 30;
  }
}