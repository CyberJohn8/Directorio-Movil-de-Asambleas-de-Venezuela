import '../models/iglesia.dart';

class MockDataService {
  static List<Iglesia> getMockIglesias() {
    return [
      Iglesia(
        id: 1,
        asamblea: 'ACARIGUA',
        numero: '001',
        ciudad: 'Acarigua',
        estado: 'Portuguesa',
        direccion: 'Calle Principal, Centro',
        domingo: '9:00 AM - 11:00 AM',
        lunes: '7:00 PM - 8:30 PM',
        martes: 'No hay reunión',
        miercoles: '7:00 PM - 8:30 PM',
        jueves: 'No hay reunión',
        viernes: '7:00 PM - 8:30 PM',
        sabado: '4:00 PM - 6:00 PM',
        obras: '• Escuela Dominical\n• Grupo de Jóvenes\n• Estudio Bíblico los miércoles\n• Oración los viernes',
        googleMaps: 'https://maps.google.com/?q=Acarigua',
        coordenadas: '9.5536, -69.1956',
        fechaFundacion: '1985-03-15',
      ),
      // Agrega más iglesias de respaldo aquí
    ];
  }
}