// Pantalla de eventos aún no implementada.
// Aquí se puede agregar la UI principal de la lista y filtros de eventos.


import 'package:flutter/material.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Pantalla de Eventos - En construcción'),
      ),
    );
  }
}