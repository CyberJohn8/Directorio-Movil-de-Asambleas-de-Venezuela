// lib/utils/api_service.dart
import 'package:flutter/foundation.dart';
import '../models/iglesia.dart';
import '../services/data_manager.dart';

class ApiService {
  static final DataManager _dataManager = DataManager();
  
  // ==================== MÉTODOS PARA IGLESIAS ====================
  
  // Obtener todas las iglesias (con respaldo automático)
  static Future<List<Iglesia>> getIglesias() async {
    try {
      // Verificar disponibilidad de DB
      await _dataManager.checkDbConnection();
      
      // Obtener iglesias (automáticamente usa DB o respaldo)
      final iglesias = await _dataManager.getIglesias();
      
      if (kDebugMode) {
        debugPrint('✅ ApiService: ${iglesias.length} iglesias obtenidas (DB disponible: ${_dataManager.dbAvailable})');
      }
      
      return iglesias;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ApiService error en getIglesias: $e');
      }
      // Intentar obtener del respaldo directamente como último recurso
      try {
        final backupIglesias = await _dataManager.getIglesias(forceRefresh: true);
        return backupIglesias;
      } catch (backupError) {
        if (kDebugMode) {
          debugPrint('❌ Error cargando respaldo de iglesias: $backupError');
        }
        return [];
      }
    }
  }
  
  // Obtener una iglesia por ID (con respaldo)
  static Future<Iglesia?> getIglesiaById(int id) async {
    try {
      // Intentar primero con la base de datos
      if (_dataManager.dbAvailable) {
        try {
          final iglesias = await _dataManager.getIglesias();
          // Buscar la iglesia, si no existe retornar null
          try {
            final iglesia = iglesias.firstWhere((i) => i.id == id);
            return iglesia;
          } catch (e) {
            // Si no se encuentra, buscar en respaldo
            if (kDebugMode) {
              debugPrint('⚠️ Iglesia $id no encontrada en DB, buscando en respaldo');
            }
            final backupIglesias = await _dataManager.getIglesias(forceRefresh: true);
            try {
              return backupIglesias.firstWhere((i) => i.id == id);
            } catch (e2) {
              return null;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error buscando iglesia $id en DB: $e');
          }
          // Si hay error en DB, buscar en respaldo
          final backupIglesias = await _dataManager.getIglesias(forceRefresh: true);
          try {
            return backupIglesias.firstWhere((i) => i.id == id);
          } catch (e2) {
            return null;
          }
        }
      } else {
        // Si DB no está disponible, buscar directamente en respaldo
        final backupIglesias = await _dataManager.getIglesias(forceRefresh: true);
        try {
          return backupIglesias.firstWhere((i) => i.id == id);
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo iglesia $id: $e');
      }
      return null;
    }
  }
  
  // Obtener iglesias filtradas por estado
  static Future<List<Iglesia>> getIglesiasByEstado(String estado) async {
    try {
      final todas = await getIglesias();
      return todas.where((i) => 
        i.estado.toLowerCase() == estado.toLowerCase()
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error filtrando iglesias por estado: $e');
      }
      return [];
    }
  }
  
  // Obtener iglesias filtradas por ciudad
  static Future<List<Iglesia>> getIglesiasByCiudad(String ciudad) async {
    try {
      final todas = await getIglesias();
      return todas.where((i) => 
        i.ciudad.toLowerCase().contains(ciudad.toLowerCase())
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error filtrando iglesias por ciudad: $e');
      }
      return [];
    }
  }
  
  // Buscar iglesias por nombre
  static Future<List<Iglesia>> searchIglesias(String query) async {
    try {
      final todas = await getIglesias();
      final queryLower = query.toLowerCase();
      return todas.where((i) => 
        i.asamblea.toLowerCase().contains(queryLower) ||
        i.estado.toLowerCase().contains(queryLower) ||
        i.ciudad.toLowerCase().contains(queryLower)
      ).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error buscando iglesias: $e');
      }
      return [];
    }
  }
  
  // ==================== MÉTODOS DE ESTADO ====================
  
  // Verificar si la base de datos está disponible
  static Future<bool> isDatabaseAvailable() async {
    await _dataManager.checkDbConnection();
    return _dataManager.dbAvailable;
  }
  
  // Refrescar todos los datos
  static Future<void> refreshAllData() async {
    await _dataManager.refreshAllData();
  }
  
  // Obtener estado de la conexión (síncrono)
  static bool get isDbAvailable => _dataManager.dbAvailable;
}