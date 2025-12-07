import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: unused_import
import 'dart:math' show asin, cos, sin, sqrt;
import '../models/service_model.dart';

class ServiceProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ServiceModel> _services = [];
  List<ServiceModel> _myServices = [];
  bool _isLoading = false;
  String? _selectedCategory;

  List<ServiceModel> get services => _services;
  List<ServiceModel> get myServices => _myServices;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;

  Future<void> fetchServices({String? category}) async {
    _isLoading = true;
    notifyListeners();

    try {
      var query = _supabase
          .from('services')
          .select()
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
        _selectedCategory = category;
      } else {
        _selectedCategory = null;
      }

      final response = await query.order('created_at', ascending: false);

      _services = (response as List)
          .map((item) => ServiceModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error fetching services: $error');
      _services = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyServices(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _myServices = (response as List)
          .map((item) => ServiceModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error fetching my services: $error');
      _myServices = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addService(ServiceModel service) async {
    try {
      final serviceData = service.toMap();
      
      // Eliminar campos que no deben enviarse al crear
      serviceData.remove('rating');
      serviceData.remove('total_reviews');
      
      await _supabase.from('services').insert(serviceData);
      
      // Actualizar la lista de servicios
      await fetchMyServices(service.userId);
      await fetchServices();
    } catch (error) {
      debugPrint('Error adding service: $error');
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel service) async {
    try {
      final serviceData = service.toMap();
      
      // Eliminar campos que no deben actualizarse
      serviceData.remove('id');
      serviceData.remove('created_at');
      
      await _supabase
          .from('services')
          .update(serviceData)
          .eq('id', service.id);
      
      // Actualizar las listas
      await fetchMyServices(service.userId);
      await fetchServices();
    } catch (error) {
      debugPrint('Error updating service: $error');
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId, String userId) async {
    try {
      await _supabase
          .from('services')
          .update({'is_active': false})
          .eq('id', serviceId);
      
      // Actualizar las listas
      await fetchMyServices(userId);
      await fetchServices();
    } catch (error) {
      debugPrint('Error deleting service: $error');
      rethrow;
    }
  }

  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('id', serviceId)
          .single();

      // ignore: unnecessary_cast
      return ServiceModel.fromMap(response as Map<String, dynamic>);
    } catch (error) {
      debugPrint('Error getting service by id: $error');
      return null;
    }
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,tags.cs.{$query}')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ServiceModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error searching services: $error');
      
      // Método alternativo: buscar en memoria
      try {
        if (_services.isEmpty) {
          await fetchServices();
        }
        
        final queryLower = query.toLowerCase();
        return _services.where((service) {
          final title = service.title.toLowerCase();
          final description = service.description.toLowerCase();
          final tagsString = service.tags.join(' ').toLowerCase();
          
          return title.contains(queryLower) || 
                 description.contains(queryLower) ||
                 tagsString.contains(queryLower);
        }).toList();
      } catch (e) {
        debugPrint('Alternative search also failed: $e');
        return [];
      }
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    try {
      final response = await _supabase
          .from('services')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => ServiceModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error getting services by category: $error');
      return [];
    }
  }

  Future<List<ServiceModel>> getNearbyServices({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    try {
      // Obtener todos los servicios activos con coordenadas
      final response = await _supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      final allServices = (response as List)
          .map((item) => ServiceModel.fromMap(item as Map<String, dynamic>))
          .toList();

      // Filtrar por distancia en el lado del cliente
      return allServices.where((service) {
        if (service.latitude == null || service.longitude == null) {
          return false;
        }
        
        final distance = _calculateDistance(
          latitude,
          longitude,
          service.latitude!,
          service.longitude!,
        );
        
        return distance <= radiusInKm;
      }).toList();
    } catch (error) {
      debugPrint('Error getting nearby services: $error');
      return [];
    }
  }

  // Calcular distancia usando la fórmula de Haversine
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() *
        _degreesToRadians(lat2).cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final c = 2 * a.sqrt().asin();
    
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180.0;
  }

  void clearCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  void clearServices() {
    _services = [];
    _myServices = [];
    _selectedCategory = null;
    notifyListeners();
  }
}

extension on double {
  sin() {}
  
  cos() {}
}