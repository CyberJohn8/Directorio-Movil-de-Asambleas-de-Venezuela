// lib/screens/estudio_biblico/estudio_screen.dart
import 'package:flutter/material.dart';
import 'biblia_screen.dart';
import 'himnario_screen.dart';
import 'buscador_biblia.dart'; // ← Importar el nuevo buscador
// Cryptogram moved to main menu; imports removed from this screen.
import '../../utils/theme.dart';

class EstudioScreen extends StatelessWidget {
  const EstudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Estudio Bíblico'),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMenuItem(
                  context,
                  titulo: 'Biblia',
                  color: AppTheme.color6,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BibliaScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // _buildMenuItem(
                //   context,
                //   titulo: 'Buscador Bíblico',
                //   color: AppTheme.color6,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => const BuscadorBibliaScreen()),
                //     );
                //   },
                // ),
                // const SizedBox(height: 16),
                
                _buildMenuItem(
                  context,
                  titulo: 'Himnario',
                  color: AppTheme.color6,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HimnarioScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),

                
                
                // Criptograma moved to main menu
                
                // _buildMenuItem(
                //   context,
                //   titulo: 'Preguntar con BibleGPT',
                //   color: AppTheme.color6,
                //   onTap: () async {
                //     const url = 'https://www.yeschat.ai/es/gpts-ZxX36KFX-BibleGPT';
                //     if (await canLaunchUrl(Uri.parse(url))) {
                //       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                //     } else {
                //       if (context.mounted) {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(content: Text('No se pudo abrir el chat GPT.')),
                //         );
                //       }
                //     }
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String titulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Center(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.color4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Cryptogram accessed from main menu now; difficulty dialog removed from this screen.
}