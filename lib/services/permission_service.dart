import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Singleton
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // 👈 SOLO PERMISO DE UBICACIÓN
  final List<Permission> _requiredPermissions = [
    Permission.location,
  ];

  // Estado de permisos
  bool _allPermissionsGranted = false;
  bool get allPermissionsGranted => _allPermissionsGranted;

  // ========== VERIFICAR PERMISOS ==========
  Future<bool> checkPermissions() async {
    try {
      for (var permission in _requiredPermissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          _allPermissionsGranted = false;
          return false;
        }
      }
      _allPermissionsGranted = true;
      return true;
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      return false;
    }
  }

  // ========== SOLICITAR PERMISOS ==========
  Future<bool> requestPermissions() async {
    try {
      for (var permission in _requiredPermissions) {
        final status = await permission.request();
        if (!status.isGranted) {
          _allPermissionsGranted = false;
          return false;
        }
      }
      _allPermissionsGranted = true;
      return true;
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      return false;
    }
  }

  // ========== VERIFICAR Y SOLICITAR SI ES NECESARIO ==========
  Future<bool> ensurePermissions() async {
    final hasPermissions = await checkPermissions();
    if (hasPermissions) {
      return true;
    }
    return await requestPermissions();
  }

  // ========== MOSTRAR DIÁLOGO DE PERMISOS SOLO SI ES NECESARIO ==========
  Future<bool> showPermissionDialogIfNeeded(BuildContext context) async {
    final hasPermissions = await checkPermissions();
    
    if (hasPermissions) {
      debugPrint('✅ Permiso de ubicación ya concedido');
      return true;
    }

    debugPrint('⚠️ Falta permiso de ubicación, mostrando diálogo');
    return await _showPermissionDialog(context);
  }

  // ========== DIÁLOGO DE PERMISOS (PRIVADO) ==========
  Future<bool> _showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Theme.of(context).primaryColor,
                size: 16, //cambiar tamaño del titulo
              ),
              const SizedBox(width: 10),
              const Text(
                'Permiso de Ubicación',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La aplicación necesita acceso a tu ubicación para:',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Sansation',
                ),
              ),
              const SizedBox(height: 12),
              _buildPermissionItem(
                icon: Icons.location_on_rounded,
                title: 'Ubicación',
                description: 'Mostrar iglesias cercanas y calcular distancias',
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Puedes gestionar este permiso desde la configuración del sistema en cualquier momento.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                          fontFamily: 'Sansation',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context, false);
              },
              child: const Text(
                'Abrir Configuración',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF637983),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Solicitar Permiso',
                style: TextStyle(
                  fontFamily: 'Sansation',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final granted = await requestPermissions();
      if (!granted) {
        if (context.mounted) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
      return true;
    }
    return false;
  }

  // ========== DIÁLOGO DE PERMISO DENEGADO ==========
  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Permiso Denegado',
            style: TextStyle(
              fontFamily: 'Sansation',
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'El permiso de ubicación fue denegado. La aplicación podría no mostrar correctamente las iglesias cercanas.\n\n'
            'Puedes habilitar el permiso desde la configuración del sistema.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Sansation',
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text(
                'Abrir Configuración',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF637983),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Continuar sin permiso',
                style: TextStyle(
                  fontFamily: 'Sansation',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========== WIDGET PARA ITEM DE PERMISO ==========
  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF637983),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sansation',
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Sansation',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== VERIFICAR Y SOLICITAR AL INICIAR ==========
  Future<void> checkAndRequestOnStartup(BuildContext context) async {
    final hasPermissions = await checkPermissions();
    
    if (hasPermissions) {
      debugPrint('✅ Permiso de ubicación ya concedido al iniciar');
      return;
    }

    debugPrint('⚠️ Falta permiso de ubicación al iniciar, mostrando diálogo');
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (context.mounted) {
      final granted = await showPermissionDialogIfNeeded(context);
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de ubicación no activo. Las iglesias cercanas no se mostrarán.',
              style: TextStyle(fontFamily: 'Sansation'),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }
}