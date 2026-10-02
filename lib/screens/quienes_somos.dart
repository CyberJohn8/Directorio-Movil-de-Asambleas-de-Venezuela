import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../utils/theme.dart'; // Importar el tema para usar AppTheme

/// Pantalla que muestra información sobre la congregación
/// utilizando un diseño de acordeón (secciones expandibles)
class QuienesSomosScreen extends StatefulWidget {
  const QuienesSomosScreen({super.key});

  @override
  State<QuienesSomosScreen> createState() => _QuienesSomosScreenState();
}

class _QuienesSomosScreenState extends State<QuienesSomosScreen> {
  String? _seccionExpandida;

  final List<SeccionInfo> _secciones = [
    const SeccionInfo(
      id: 'somos',
      titulo: '¿Quiénes Somos?',
      contenido: '''
Somos cristianos, que nos congregamos sencillamente en el nombre del Señor Jesucristo, como Él lo señaló en Mateo 18:20

"Porque donde están dos o tres congregados en mi nombre, allí estoy yo en medio de ellos"
''',
      versiculo: 'Mateo 18:20',
    ),
    const SeccionInfo(
      id: 'denominados',
      titulo: '¿Cómo nos denominamos?',
      contenido: '''
No pertenecemos a ninguna organización religiosa (ni política)

Juan 15:19: "Si fuerais del mundo, el mundo amaría lo suyo; pero porque no sois del mundo, antes yo os elegí del mundo, por eso el mundo os aborrece"
''',
      versiculo: 'Juan 15:19',
    ),
    const SeccionInfo(
      id: 'lider',
      titulo: '¿Quién nos lidera?',
      contenido: '''
No nos preside un líder religioso aquí en la tierra (llámese papa, pastor, reverendo, etc.), sino el mismo Señor Jesucristo a través de su Santa Palabra (La Biblia).

Colosenses 1:18: "y él es la cabeza del cuerpo que es la iglesia, él que es el principio, el primogénito de entre los muertos, para que en todo tenga la preeminencia"
''',
      versiculo: 'Colosenses 1:18',
    ),
    const SeccionInfo(
      id: 'congregacion',
      titulo: '¿Cómo nos congregamos?',
      contenido: '''
Predicamos el evangelio "decentemente y con orden"

1 Corintios 14:40: "pero hágase todo decentemente y con orden", sin alboroto y sin nada que esté reñido con el comportamiento civilizado de la conducta humana.
''',
      versiculo: '1 Corintios 14:40',
    ),
    const SeccionInfo(
      id: 'donaciones',
      titulo: '¿Donaciones?',
      contenido: '''
No pedimos dinero a nuestros oyentes (ni practicamos el diezmo), porque Dios no está buscando tu dinero, sino tu corazón, para darte salvación.

Lucas 19:46 Jesús dijo: "Escrito está: Mi casa es casa de oración; mas vosotros la habéis hecho cueva de ladrones".
''',
      versiculo: 'Lucas 19:46',
    ),
    const SeccionInfo(
      id: 'hacemos',
      titulo: '¿Qué hacemos?',
      contenido: '''
Predicamos el mensaje de Dios, que todos los seres humanos pecaron, incluso usted, y que a causa del pecado estamos separados de Dios, pero que Él nos amó en su hijo Jesucristo, quien murió en nuestro lugar para salvarnos.

Romanos 3:23-24: "por cuanto todos pecaron, y están destituidos de la gloria de Dios, siendo justificados gratuitamente por su gracia, mediante la redención que es en Cristo Jesús"
''',
      versiculo: 'Romanos 3:23-24',
    ),
    const SeccionInfo(
      id: 'porque',
      titulo: '¿Por qué lo hacemos?',
      contenido: '''
Predicamos que todo aquel que se arrepiente de sus pecados y acepta a Cristo como su Salvador personal es salvo del infierno y tiene vida eterna en los cielos.

1 Pedro 1:3-4: "Bendito el Dios y Padre de nuestro Señor Jesucristo, que según su grande misericordia nos hizo renacer para una esperanza viva, por la resurrección de Jesucristo de los muertos para una herencia incorruptible, incontaminada e inmarcesible, reservada en los cielos para vosotros"
''',
      versiculo: '1 Pedro 1:3-4',
    ),
    const SeccionInfo(
      id: 'donde',
      titulo: '¿Dónde encontrarnos?',
      contenido: '''
Para más información puede emplear esta APP para:

• Localizar el Local Evangélico más cercano a su localidad 
  empleando la función "Ubicaciones"

• Consultar la Biblia con las funciones de "Estudio Bíblico"

• Revisar el material en la sección de "Material Literario"
''',
      versiculo: null,
    ),
  ];

  void _toggleSeccion(String id) {
    setState(() {
      _seccionExpandida = (_seccionExpandida == id) ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      
      // ===== BARRA SUPERIOR =====
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('¿Quiénes Somos?'),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icons/menu.png',
                width: 24,
                height: 24,
                color: AppTheme.color4,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.menu, color: Colors.white);
                },
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú',
            ),
          ),
        ],
      ),
      
      // ===== CUERPO PRINCIPAL =====
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                    _buildTituloPrincipal(),
                const SizedBox(height: 20),
                _buildAcordeon(),
                    const SizedBox(height: 30),
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTituloPrincipal() {
    return Center(
      child: Column(
        children: [
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: 0.6), //MODIFICAR ESTE COLOR PARA LOGRAR EL EFECTO DE TRANSPARENCIA (0.0 = totalmente transparente, 1.0 = opaco)
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(
          //     Icons.church,
          //     size: 60,
          //     color: Color(0xFF637983),
          //   ),
          // ),
          const SizedBox(height: 10),
          Text(
            'Asambleas Congregadas\n al Nombre del Señor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2a3e42),
                  fontFamily: 'OleoScript',
                  height: 1.3,
                ) ?? const TextStyle(fontSize: 26, color: Color(0xFF2a3e42)),
          ),
        ],
      ),
    );
  }

  Widget _buildAcordeon() {
    return Column(
      children: _secciones.map((seccion) {
        return _buildSeccion(seccion);
      }).toList(),
    );
  }

  Widget _buildSeccion(SeccionInfo seccion) {
    final bool estaExpandida = _seccionExpandida == seccion.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _toggleSeccion(seccion.id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                border: estaExpandida
                    ? const Border(
                        bottom: BorderSide(
                          color: Color(0xFF637983),
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      seccion.titulo,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF2a3e42),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: estaExpandida ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.expand_more,
                      size: 24,
                      color: Color(0xFF637983),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seccion.contenido,
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF2a3e42),
                    ),
                  ),
                  if (seccion.versiculo != null) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.color6.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.color6.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_quote,
                            size: 20,
                            color: Color(0xFF637983),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              seccion.versiculo!,
                              style: const TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF637983),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: estaExpandida
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

}

/// Modelo de datos para cada sección del acordeón
class SeccionInfo {
  final String id;
  final String titulo;
  final String contenido;
  final String? versiculo;

  const SeccionInfo({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.versiculo,
  });
}