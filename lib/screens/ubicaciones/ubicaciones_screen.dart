import 'package:flutter/material.dart';

class UbicacionesScreen extends StatelessWidget {
  const UbicacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar de la pantalla de Ubicaciones
      appBar: AppBar(
        title: Text('Ubicaciones', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Container(
        // Fondo de la pantalla de Ubicaciones
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Text('Pantalla de Ubicaciones'),
        ),
      ),
    );
  }
}