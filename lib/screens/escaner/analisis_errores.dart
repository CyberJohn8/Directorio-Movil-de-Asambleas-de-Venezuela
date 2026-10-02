import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';  // 👈 IMPORTAR url_launcher
import '../../utils/config.dart';
import '../../services/api_service.dart';
import '../../services/local_database_service.dart';
import '../../utils/theme.dart';
import '../../models/iglesia.dart';
import '../../utils/launch_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class AnalisisErroresScreen extends StatefulWidget {
  const AnalisisErroresScreen({super.key});

  @override
  State<AnalisisErroresScreen> createState() => _AnalisisErroresScreenState();
}

class _AnalisisErroresScreenState extends State<AnalisisErroresScreen> {
  List<DiagnosticoItem> diagnosticos = [];
  bool estaAnalizando = false;
  String resultadoGeneral = '';

  static const String emailContacto = 'directorioasambleas@gmail.com';

  @override
  void initState() {
    super.initState();
    _iniciarDiagnostico();
  }

  // ========== FUNCIÓN PARA ENVIAR CORREO ==========
  Future<void> _enviarCorreo(BuildContext context) async {
    final bool launched = await sendEmailWithIntent(
      context,
      email: emailContacto,
      asunto: 'Reporte de Diagnóstico - Directorio de Asambleas',
      cuerpo: 'Hola,\n\n'
              'Estoy enviando este reporte de diagnóstico para ayudar a mejorar la aplicación.\n\n'
              '=== RESULTADO DEL DIAGNÓSTICO ===\n'
              '$resultadoGeneral\n\n'
              '=== DETALLES ===\n'
              '${_obtenerResumenDiagnostico()}\n\n'
              'Gracias por tu atención.',
    );
    
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el cliente de correo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _obtenerResumenDiagnostico() {
    StringBuffer buffer = StringBuffer();
    for (var item in diagnosticos) {
      String emoji = item.estado == EstadoDiagnostico.exito ? '✅' :
                     item.estado == EstadoDiagnostico.advertencia ? '⚠️' : '❌';
      buffer.writeln('$emoji ${item.titulo}: ${item.descripcion}');
      buffer.writeln('   Detalles: ${item.detalles}');
      buffer.writeln('');
    }
    return buffer.toString();
  }

  Future<void> _iniciarDiagnostico() async {
    setState(() {
      estaAnalizando = true;
      diagnosticos.clear();
      resultadoGeneral = '🔍 Iniciando diagnóstico...';
    });

    await _diagnosticarTodo();

    setState(() {
      estaAnalizando = false;
      _actualizarResultadoGeneral();
    });
  }

  void _actualizarResultadoGeneral() {
    int errores = diagnosticos.where((d) => d.estado == EstadoDiagnostico.error).length;
    int advertencias = diagnosticos.where((d) => d.estado == EstadoDiagnostico.advertencia).length;

    if (errores == 0 && advertencias == 0) {
      resultadoGeneral = '✅ ¡Todo funciona correctamente!';
    } else if (errores == 0 && advertencias > 0) {
      resultadoGeneral = '⚠️ $advertencias advertencia(s) encontrada(s), pero la app debería funcionar';
    } else {
      resultadoGeneral = '❌ $errores error(es) encontrado(s). Revisa los detalles abajo.';
    }
  }

  Future<void> _diagnosticarTodo() async {
    await _verificarPermisos();
    await _verificarInternet();
    await _verificarConfiguracion();
    await _verificarServidor();
    await _verificarBaseDatosLocalDetallado();
    await _verificarAssets();
    await _verificarModelos();
    await _probarApi();
    await _verificarEmail();
  }

  // ========== DIAGNÓSTICO DE CORREO ==========
  Future<void> _verificarEmail() async {
    try {
      // Construir URI de prueba
      final testUri = Uri.parse('mailto:test@example.com');
      
      // Verificar si se puede lanzar
      bool canLaunch = false;
      String errorDetalle = '';
      
      try {
        canLaunch = await canLaunchUrl(testUri);  // 👈 CORREGIDO: usar canLaunchUrl
      } catch (e) {
        errorDetalle = e.toString();
      }
      
      String detalles = '';
      String descripcion = '';
      EstadoDiagnostico estado;
      
      if (canLaunch) {
        estado = EstadoDiagnostico.exito;
        descripcion = '✅ El dispositivo puede manejar enlaces mailto:';
        detalles = 'Se detectó un cliente de correo en el dispositivo.\n\n';
        detalles += '📧 Correo de contacto: $emailContacto\n';
        detalles += '✅ El correo debería funcionar correctamente.\n\n';
        detalles += 'Si aún no funciona, verifica que:\n';
        detalles += '• Hay una cuenta de correo configurada en Gmail\n';
        detalles += '• Gmail está actualizado\n';
        detalles += '• El emulador tiene Play Services actualizados';
      } else {
        estado = EstadoDiagnostico.error;
        descripcion = '❌ No se detectó cliente de correo';
        detalles = 'No se encontró una aplicación que maneje enlaces mailto:\n\n';
        detalles += '📧 Correo de contacto: $emailContacto\n';
        detalles += '🔍 Error: $errorDetalle\n\n';
        detalles += '💡 SOLUCIONES:\n';
        detalles += '1. Instala Gmail desde Play Store\n';
        detalles += '2. Configura una cuenta de Google en el dispositivo\n';
        detalles += '3. Abre Gmail al menos una vez para configurarlo\n';
        detalles += '4. Asegúrate de que Gmail está actualizado\n';
        detalles += '5. Si usas emulador, asegúrate de tener Play Services\n\n';
        detalles += '📝 ALTERNATIVA:\n';
        detalles += 'La app permite copiar el correo al portapapeles\n';
        detalles += 'y enviarlo manualmente desde cualquier cliente de correo.';
      }
      
      diagnosticos.add(DiagnosticoItem(
        titulo: '📧 Cliente de Correo',
        descripcion: descripcion,
        estado: estado,
        detalles: detalles,
      ));
      
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: '📧 Cliente de Correo',
        descripcion: 'Error al verificar cliente de correo',
        estado: EstadoDiagnostico.error,
        detalles: 'Error: $e\nStack trace: ${StackTrace.current}',
      ));
    }
  }

  // ========== FUNCIONES DE DIAGNÓSTICO EXISTENTES ==========

  Future<void> _verificarPermisos() async {
    try {
      bool tienePermisos = true;
      if (Platform.isAndroid) {
        tienePermisos = true;
      }
      
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Permisos de almacenamiento',
        descripcion: 'La app tiene permisos para acceder al almacenamiento',
        estado: tienePermisos ? EstadoDiagnostico.exito : EstadoDiagnostico.error,
        detalles: tienePermisos ? 'Permisos concedidos correctamente' : 'Faltan permisos de almacenamiento',
      ));
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Permisos de almacenamiento',
        descripcion: 'Error al verificar permisos',
        estado: EstadoDiagnostico.error,
        detalles: e.toString(),
      ));
    }
  }

  Future<void> _verificarInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        diagnosticos.add(DiagnosticoItem(
          titulo: 'Conexión a Internet',
          descripcion: 'La app tiene acceso a internet',
          estado: EstadoDiagnostico.exito,
          detalles: 'Conexión activa',
        ));
      } else {
        diagnosticos.add(DiagnosticoItem(
          titulo: 'Conexión a Internet',
          descripcion: 'No se detectó conexión a internet',
          estado: EstadoDiagnostico.error,
          detalles: 'Verifica que el dispositivo esté conectado a WiFi o datos móviles',
        ));
      }
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Conexión a Internet',
        descripcion: 'Error al verificar conexión',
        estado: EstadoDiagnostico.error,
        detalles: e.toString(),
      ));
    }
  }

  Future<void> _verificarConfiguracion() async {
    try {
      String apiUrl = Config.apiUrl;
      bool isProduction = Config.isProduction;
      
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Configuración de la App',
        descripcion: 'Configuración cargada correctamente',
        estado: EstadoDiagnostico.exito,
        detalles: 'URL: $apiUrl\nModo: ${isProduction ? "Producción" : "Desarrollo"}',
      ));
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Configuración de la App',
        descripcion: 'Error al cargar configuración',
        estado: EstadoDiagnostico.error,
        detalles: e.toString(),
      ));
    }
  }

  Future<void> _verificarServidor() async {
    try {
      String url = '${Config.apiUrl}/test_connection.php';
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        try {
          var data = json.decode(response.body);
          diagnosticos.add(DiagnosticoItem(
            titulo: 'Servidor en línea',
            descripcion: 'El servidor responde correctamente',
            estado: EstadoDiagnostico.exito,
            detalles: 'URL: $url\nRespuesta: ${data['message'] ?? 'OK'}',
          ));
        } catch (e) {
          diagnosticos.add(DiagnosticoItem(
            titulo: 'Servidor en línea',
            descripcion: 'El servidor responde pero la respuesta no es JSON válido',
            estado: EstadoDiagnostico.advertencia,
            detalles: 'URL: $url\nRespuesta: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
          ));
        }
      } else {
        diagnosticos.add(DiagnosticoItem(
          titulo: 'Servidor en línea',
          descripcion: 'El servidor no responde correctamente',
          estado: EstadoDiagnostico.error,
          detalles: 'URL: $url\nCódigo: ${response.statusCode}\nRespuesta: ${response.body}',
        ));
      }
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Servidor en línea',
        descripcion: 'Error al conectar con el servidor',
        estado: EstadoDiagnostico.error,
        detalles: 'URL: ${Config.apiUrl}/test_connection.php\nError: $e',
      ));
    }
  }

  Future<void> _verificarBaseDatosLocalDetallado() async {
    try {
      final db = await LocalDatabaseService().database;
      
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      int tablaCount = tables.length;
      
      List<String> nombresTablas = [];
      for (var table in tables) {
        nombresTablas.add(table['name'] as String);
      }
      
      Map<String, int> conteoPorTabla = {};
      for (String nombre in nombresTablas) {
        try {
          final result = await db.query(nombre);
          conteoPorTabla[nombre] = result.length;
        } catch (e) {
          conteoPorTabla[nombre] = -1;
        }
      }
      
      int iglesiasCount = conteoPorTabla['iglesias'] ?? 0;
      
      String diagnosticoAdicional = '';
      if (iglesiasCount == 0 && tablaCount > 0) {
        diagnosticoAdicional = '\n⚠️ La tabla iglesias existe pero está vacía.';
        
        bool hayDatosEnOtrasTablas = false;
        for (var entry in conteoPorTabla.entries) {
          if (entry.key != 'iglesias' && entry.value > 0) {
            hayDatosEnOtrasTablas = true;
            diagnosticoAdicional += '\n   - Tabla "${entry.key}" tiene ${entry.value} registros';
          }
        }
        
        if (!hayDatosEnOtrasTablas) {
          diagnosticoAdicional += '\n   - Ninguna tabla tiene datos. El archivo SQL puede no tener INSERTS.';
          diagnosticoAdicional += '\n   - Solución: El sistema intentará insertar datos de ejemplo automáticamente.';
        }
      }
      
      String detalles = 'Tablas: $tablaCount\n';
      detalles += 'Lista de tablas: ${nombresTablas.join(", ")}\n';
      detalles += 'Iglesias: $iglesiasCount\n';
      
      List<String> tablasPrincipales = ['himnos', 'sitios_web', 'coritos', 'books', 'verses', 'instituciones', 'mensajes', 'usuarios'];
      for (String tabla in tablasPrincipales) {
        if (conteoPorTabla.containsKey(tabla)) {
          detalles += '$tabla: ${conteoPorTabla[tabla]}\n';
        }
      }
      
      detalles += diagnosticoAdicional;
      
      EstadoDiagnostico estado;
      String descripcion;
      
      if (iglesiasCount > 0) {
        estado = EstadoDiagnostico.exito;
        descripcion = 'Base de datos local con datos';
      } else if (tablaCount > 0) {
        estado = EstadoDiagnostico.advertencia;
        descripcion = 'Base de datos local sin datos en iglesias';
      } else {
        estado = EstadoDiagnostico.error;
        descripcion = 'Base de datos local sin tablas';
      }
      
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Base de Datos Local (Detallado)',
        descripcion: descripcion,
        estado: estado,
        detalles: detalles,
      ));
      
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Base de Datos Local (Detallado)',
        descripcion: 'Error al inicializar la base de datos local',
        estado: EstadoDiagnostico.error,
        detalles: 'Error: $e\nStack trace: ${StackTrace.current}',
      ));
    }
  }

  Future<void> _verificarAssets() async {
    try {
      String sqlContent = await rootBundle.loadString('assets/directorio.sql');
      int lineas = sqlContent.split('\n').length;
      
      int insertCount = 0;
      int createCount = 0;
      List<String> lines = sqlContent.split('\n');
      for (String line in lines) {
        String upperLine = line.toUpperCase().trim();
        if (upperLine.startsWith('INSERT')) {
          insertCount++;
        }
        if (upperLine.startsWith('CREATE')) {
          createCount++;
        }
      }
      
      bool tieneTablaIglesias = sqlContent.toUpperCase().contains('CREATE TABLE IF NOT EXISTS IGLESIAS') ||
                                sqlContent.toUpperCase().contains('CREATE TABLE IGLESIAS');
      
      bool tieneInsertsIglesias = sqlContent.toUpperCase().contains('INSERT INTO IGLESIAS') ||
                                  sqlContent.toUpperCase().contains('INSERT OR IGNORE INTO IGLESIAS');
      
      String detalles = 'Tamaño: ${sqlContent.length} caracteres\n';
      detalles += 'Líneas: $lineas\n';
      detalles += 'CREATE statements: $createCount\n';
      detalles += 'INSERT statements: $insertCount\n';
      detalles += 'Contiene tabla iglesias: ${tieneTablaIglesias ? "✅ Sí" : "❌ No"}\n';
      detalles += 'Contiene INSERTS para iglesias: ${tieneInsertsIglesias ? "✅ Sí" : "❌ No"}';
      
      EstadoDiagnostico estado;
      if (tieneTablaIglesias && tieneInsertsIglesias) {
        estado = EstadoDiagnostico.exito;
      } else if (tieneTablaIglesias) {
        estado = EstadoDiagnostico.advertencia;
        detalles += '\n⚠️ El SQL tiene la tabla pero NO tiene datos INSERT para iglesias.';
      } else {
        estado = EstadoDiagnostico.error;
        detalles += '\n❌ El SQL NO tiene la tabla iglesias.';
      }
      
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Archivos Assets (Detallado)',
        descripcion: 'Análisis del archivo SQL',
        estado: estado,
        detalles: detalles,
      ));
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Archivos Assets',
        descripcion: 'No se pudo cargar el archivo SQL',
        estado: EstadoDiagnostico.error,
        detalles: 'Error: $e\nVerifica que el archivo existe en assets/directorio.sql',
      ));
    }
  }

  Future<void> _verificarModelos() async {
    try {
      final testIglesia = Iglesia(
        id: 1,
        asamblea: 'Test',
        numero: '001',
        estado: 'Test',
        ciudad: 'Test',
        direccion: 'Dirección de prueba',
        domingo: null,
        lunes: null,
        martes: null,
        miercoles: null,
        jueves: null,
        viernes: null,
        sabado: null,
        obras: null,
        googleMaps: 'https://maps.google.com/test',
        coordenadas: null,
        fechaFundacion: '2024-01-01',
      );
      
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Modelos de Datos',
        descripcion: 'Los modelos se cargan correctamente',
        estado: EstadoDiagnostico.exito,
        detalles: 'Iglesia: ${testIglesia.asamblea}\nModelos disponibles: Iglesia, Himno, SitioWeb, etc.',
      ));
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'Modelos de Datos',
        descripcion: 'Error al cargar los modelos',
        estado: EstadoDiagnostico.error,
        detalles: e.toString(),
      ));
    }
  }

  Future<void> _probarApi() async {
    try {
      final iglesias = await ApiService.getIglesias();
      
      if (iglesias.isNotEmpty) {
        diagnosticos.add(DiagnosticoItem(
          titulo: 'API - Carga de Datos',
          descripcion: 'Se cargaron datos correctamente',
          estado: EstadoDiagnostico.exito,
          detalles: '${iglesias.length} iglesias cargadas\nPrimera: ${iglesias.first.asamblea}',
        ));
      } else {
        bool usaLocal = await ApiService.shouldUseLocalDatabase();
        
        String detalles = 'La lista de iglesias está vacía.\n';
        detalles += 'Usando base de datos local: ${usaLocal ? "✅ Sí" : "❌ No"}\n';
        
        if (usaLocal) {
          detalles += '\n🔍 Posibles causas:\n';
          detalles += '1. El archivo SQL no tiene INSERTS para iglesias\n';
          detalles += '2. Los INSERTS no se ejecutaron correctamente\n';
          detalles += '3. La tabla iglesias no se creó correctamente\n';
          detalles += '\n💡 Solución: El sistema intentará insertar datos de ejemplo automáticamente.';
        } else {
          detalles += '\n🔍 El servidor está respondiendo pero devuelve datos vacíos.\n';
          detalles += 'Verifica que la base de datos en el servidor tenga datos.';
        }
        
        diagnosticos.add(DiagnosticoItem(
          titulo: 'API - Carga de Datos',
          descripcion: 'No se cargaron datos',
          estado: EstadoDiagnostico.error,
          detalles: detalles,
        ));
      }
    } catch (e) {
      diagnosticos.add(DiagnosticoItem(
        titulo: 'API - Carga de Datos',
        descripcion: 'Error al cargar datos desde la API',
        estado: EstadoDiagnostico.error,
        detalles: 'Error: $e\nStack trace: ${StackTrace.current}',
      ));
    }
  }

  void _mostrarDetalleDiagnostico(BuildContext context, DiagnosticoItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                item.estado == EstadoDiagnostico.exito ? Icons.check_circle :
                item.estado == EstadoDiagnostico.advertencia ? Icons.warning :
                Icons.error,
                color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                       item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                       Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.estado == EstadoDiagnostico.exito ? Colors.green.withValues(alpha: 0.1) :
                           item.estado == EstadoDiagnostico.advertencia ? Colors.orange.withValues(alpha: 0.1) :
                           Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                             item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                             Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.estado == EstadoDiagnostico.exito ? Icons.check_circle_outline :
                        item.estado == EstadoDiagnostico.advertencia ? Icons.warning_amber_outlined :
                        Icons.error_outline,
                        color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                               item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                               Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.estado == EstadoDiagnostico.exito ? '✅ ÉXITO' :
                        item.estado == EstadoDiagnostico.advertencia ? '⚠️ ADVERTENCIA' :
                        '❌ ERROR',
                        style: TextStyle(
                          color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                                 item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                                 Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Detalles técnicos:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    item.detalles,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (item.estado == EstadoDiagnostico.error)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _copiarDiagnostico();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Diagnóstico copiado al portapapeles')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Copiar Error'),
              ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Errores'),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: estaAnalizando ? null : _iniciarDiagnostico,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.color6.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  resultadoGeneral.contains('✅') ? Icons.check_circle :
                  resultadoGeneral.contains('⚠️') ? Icons.warning :
                  Icons.error,
                  color: resultadoGeneral.contains('✅') ? Colors.green :
                         resultadoGeneral.contains('⚠️') ? Colors.orange :
                         Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resultadoGeneral,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (estaAnalizando)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          if (!estaAnalizando && diagnosticos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContadorItem(
                    '✅ Éxitos',
                    diagnosticos.where((d) => d.estado == EstadoDiagnostico.exito).length,
                    Colors.green,
                  ),
                  _buildContadorItem(
                    '⚠️ Advertencias',
                    diagnosticos.where((d) => d.estado == EstadoDiagnostico.advertencia).length,
                    Colors.orange,
                  ),
                  _buildContadorItem(
                    '❌ Errores',
                    diagnosticos.where((d) => d.estado == EstadoDiagnostico.error).length,
                    Colors.red,
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: diagnosticos.isEmpty && !estaAnalizando
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay resultados de diagnóstico',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: diagnosticos.length,
                    itemBuilder: (context, index) {
                      final item = diagnosticos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: item.estado == EstadoDiagnostico.exito ? Colors.green.withValues(alpha: 0.3) :
                                   item.estado == EstadoDiagnostico.advertencia ? Colors.orange.withValues(alpha: 0.3) :
                                   Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _mostrarDetalleDiagnostico(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.estado == EstadoDiagnostico.exito ? Colors.green.withValues(alpha: 0.1) :
                                           item.estado == EstadoDiagnostico.advertencia ? Colors.orange.withValues(alpha: 0.1) :
                                           Colors.red.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.estado == EstadoDiagnostico.exito ? Icons.check_circle :
                                    item.estado == EstadoDiagnostico.advertencia ? Icons.warning :
                                    Icons.error,
                                    color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                                           item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                                           Colors.red,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.descripcion,
                                        style: TextStyle(
                                          color: item.estado == EstadoDiagnostico.exito ? Colors.green :
                                                 item.estado == EstadoDiagnostico.advertencia ? Colors.orange :
                                                 Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _enviarCorreo(context),
            icon: const Icon(Icons.email),
            label: const Text('Enviar Reporte'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            heroTag: 'send_report',
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            onPressed: () {
              _copiarDiagnostico();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Diagnóstico copiado al portapapeles'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Diagnóstico'),
            backgroundColor: AppTheme.color6,
            foregroundColor: AppTheme.color4,
            heroTag: 'copy_report',
          ),
        ],
      ),
    );
  }

  Widget _buildContadorItem(String label, int count, Color color) {
    return Row(
      children: [
        Icon(
          label.contains('Éxitos') ? Icons.check_circle :
          label.contains('Advertencias') ? Icons.warning :
          Icons.error,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  void _copiarDiagnostico() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('=== DIAGNÓSTICO DE LA APP ===');
    buffer.writeln('Fecha: ${DateTime.now()}');
    buffer.writeln('Resultado: $resultadoGeneral');
    buffer.writeln('\n--- DETALLES ---\n');
    
    for (var item in diagnosticos) {
      String emoji = item.estado == EstadoDiagnostico.exito ? '✅' :
                     item.estado == EstadoDiagnostico.advertencia ? '⚠️' : '❌';
      buffer.writeln('$emoji ${item.titulo}');
      buffer.writeln('   ${item.descripcion}');
      buffer.writeln('   ${item.detalles}');
      buffer.writeln('');
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }
}

enum EstadoDiagnostico { exito, advertencia, error }

class DiagnosticoItem {
  final String titulo;
  final String descripcion;
  final EstadoDiagnostico estado;
  final String detalles;

  DiagnosticoItem({
    required this.titulo,
    required this.descripcion,
    required this.estado,
    required this.detalles,
  });
}