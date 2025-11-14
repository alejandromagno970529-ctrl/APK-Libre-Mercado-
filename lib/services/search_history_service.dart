// lib/services/search_history_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 5;

  // Guardar búsqueda
  static Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> history = await getSearchHistory();
    
    // Remover si ya existe
    history.remove(query.trim());
    // Agregar al inicio
    history.insert(0, query.trim());
    // Limitar a máximo items
    if (history.length > _maxHistoryItems) {
      history = history.sublist(0, _maxHistoryItems);
    }
    
    await prefs.setStringList(_searchHistoryKey, history);
  }

  // Obtener historial
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  // Limpiar historial
  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }

  // Eliminar item específico
  static Future<void> removeSearchItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = await getSearchHistory();
    history.remove(query.trim());
    await prefs.setStringList(_searchHistoryKey, history);
  }
}