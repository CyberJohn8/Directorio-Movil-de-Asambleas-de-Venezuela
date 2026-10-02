// lib/config/backup_config.dart
class BackupConfig {
  // Nombres de archivos de respaldo
  static const String booksFile = 'books.json';
  static const String versesFile = 'verses.json';
  static const String coritosFile = 'coritos.json';
  static const String himnosFile = 'himnos.json';
  static const String iglesiasFile = 'iglesias.json';
  static const String sitiosWebFile = 'sitios_web.json';
  static const String sitiosWebOtrosFile = 'sitios_web_otros.json';
  
  // Directorio base para los archivos de respaldo
  static const String backupDirectory = 'assets/data';
  
  // Tipos de datos disponibles
  static const List<String> dataTypes = [
    'books',
    'verses', 
    'coritos',
    'himnos',
    'iglesias',
    'sitios_web',
    'sitios_web_otros'
  ];
  
  // Mapeo de tipos de datos a archivos
  static Map<String, String> getDataTypeToFileMap() {
    return {
      'books': booksFile,
      'verses': versesFile,
      'coritos': coritosFile,
      'himnos': himnosFile,
      'iglesias': iglesiasFile,
      'sitios_web': sitiosWebFile,
      'sitios_web_otros': sitiosWebOtrosFile,
    };
  }
}