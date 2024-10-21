import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'login_page.dart';

// Importando todas as páginas dos setores
import 'setores/geral_area1.dart';
import 'setores/geral_area2.dart';
import 'setores/geral_area3.dart';
import 'setores/hemodinamica_subsolo.dart';
import 'setores/hemodinamica_cc.dart';
import 'setores/gama_camara.dart';
import 'setores/ressonancia_magnetica.dart';
import 'setores/tomografo_toshiba.dart';
import 'setores/tomografo_siemens_oncologia.dart';
import 'setores/tomografo_siemens_subsolo.dart';
import 'setores/osmose_fixa01.dart';
import 'setores/osmose_fixa02.dart';
import 'setores/cme.dart';
import 'setores/cme2.dart';
import 'setores/pronto_socorro.dart';
import 'setores/uti.dart';
import 'setores/cc1.dart';
import 'setores/cc2.dart';

void main() async {
  // Garantindo que todos os bindings do Flutter estejam inicializados antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando o Firebase com as opções definidas em firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Rodando o aplicativo Flutter
  runApp(const MyApp());
}

// Classe principal do aplicativo
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo', // Título do app
      theme: ThemeData.light(), // Definindo o tema claro
      home: const LoginPage(), // Página inicial definida como LoginPage
    );
  }
}

// Definição da página principal, que receberá um título como argumento
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref(); // Referência ao banco de dados Firebase
  String userName = 'Usuário'; // Variável para armazenar o nome do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carregar os dados do usuário ao inicializar a página
  }

  // Função para carregar o nome do usuário autenticado no Firebase
  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser; // Obtendo o usuário atual autenticado
    if (user != null) {
      // Buscando o nome do usuário no caminho 'users/colaboradores' no banco de dados Firebase
      _databaseReference.child('users/colaboradores').child(user.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          // Se o snapshot de dados existe, define o nome do usuário
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        } else {
          // Se os dados não existirem, define como 'Usuário desconhecido'
          userName = 'Usuário desconhecido';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Sem cor de fundo para o AppBar
        elevation: 0, // Removendo sombra do AppBar
        title: Text(
          widget.title, // Exibe o título da página
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true, // Centralizando o título no AppBar
        leading: IconButton(
          // Botão de voltar no AppBar
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Ao clicar, retorna à página de login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        actions: [
          // Exibe o nome do usuário no canto superior direito
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blueAccent), // Ícone de pessoa
                  const SizedBox(width: 5),
                  Text(
                    userName, // Exibe o nome do usuário
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Define espaçamento interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Espaçamento entre seções
            _buildSectionCard('Rondas Gerais', 'Verifique se todas as rondas foram realizadas.', [
              'Geral Área 1',
              'Geral Área 2',
              'Geral Área 3',
            ]),
            const SizedBox(height: 20),
            _buildSectionCard('Inspeções', 'Detalhes das inspeções realizadas.', [
              'Hemodinâmica Subsolo',
              'Hemodinâmica CC',
              'Gama Câmara',
              'Ressonância Magnética',
              'Tomógrafo Toshiba',
              'Tomógrafo Siemens Oncologia',
              'Tomógrafo Siemens Subsolo',
              'Osmose Fixa 01',
              'Osmose Fixa 02',
            ]),
            const SizedBox(height: 20),
            _buildSectionCard('Ronda Setorial', 'Detalhes das rondas específicas.', [
              'CME',
              'CME 2',
              'Pronto Socorro',
              'UTI',
              'CC 1',
              'CC 2',
            ]),
          ],
        ),
      ),
    );
  }

  // Função para construir o card de seções (Rondas Gerais, Inspeções, etc.)
  Widget _buildSectionCard(String title, String description, List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Definindo bordas arredondadas
      ),
      elevation: 0, // Removendo o sombreamento
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Espaçamento interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, // Título da seção (ex: 'Rondas Gerais')
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description, // Descrição da seção
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => InkWell(
                onTap: () {
                  // Definindo navegação ao clicar em cada item da lista
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      switch (item) {
                        case 'Geral Área 1':
                          return const GeralArea1Page();
                        case 'Geral Área 2':
                          return const GeralArea2Page();
                        case 'Geral Área 3':
                          return const GeralArea3Page();
                        case 'Hemodinâmica Subsolo':
                          return const HemodinamicaSubsoloPage();
                        case 'Hemodinâmica CC':
                          return const HemodinamicaCCPage();
                        case 'Gama Câmara':
                          return const GamaCamaraPage();
                        case 'Ressonância Magnética':
                          return const RessonanciaMagneticaPage();
                        case 'Tomógrafo Toshiba':
                          return const TomografoToshibaPage();
                        case 'Tomógrafo Siemens Oncologia':
                          return const TomografoSiemensOncologiaPage();
                        case 'Tomógrafo Siemens Subsolo':
                          return const TomografoSiemensSubsoloPage();
                        case 'Osmose Fixa 01':
                          return const OsmoseFixa01Page();
                        case 'Osmose Fixa 02':
                          return const OsmoseFixa02Page();
                        case 'CME':
                          return const CMEPage();
                        case 'CME 2':
                          return const CME2Page();
                        case 'Pronto Socorro':
                          return const ProntoSocorroPage();
                        case 'UTI':
                          return const UTIPage();
                        case 'CC 1':
                          return const CC1Page();
                        case 'CC 2':
                          return const CC2Page();
                        default:
                          return const MyHomePage(title: 'Setor');
                      }
                    }),
                  );
                },
                splashFactory: NoSplash.splashFactory, // Remove animação de clique
                highlightColor: Colors.transparent, // Remove o destaque ao pressionar
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1), // Cor de fundo leve
                      borderRadius: BorderRadius.circular(8), // Bordas arredondadas
                      border: Border.all(
                        color: Colors.blueAccent, // Definindo cor da borda
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Espaçamento entre texto e ícone
                      children: [
                        Text(
                          item, // Exibe o nome do setor
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        FutureBuilder(
                          // Buscando o status de finalização do setor no Firebase
                          future: _databaseReference.child('setores/${item.toLowerCase().replaceAll(' ', '_')}').once(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator(); // Exibe carregamento enquanto espera
                            }
                            if (snapshot.hasData) {
                              var data = snapshot.data as DatabaseEvent;
                              var finalizadoValue = data.snapshot.child('finalizado').value;
                              debugPrint('Valor recebido para $item: $finalizadoValue'); // Depuração
                              
                              bool isCompleted = false; // Define se o setor foi finalizado
                              if (finalizadoValue is bool) {
                                isCompleted = finalizadoValue;
                              } else if (finalizadoValue is String) {
                                isCompleted = finalizadoValue.toLowerCase() == 'true';
                              }

                              // Exibe ícone verde se finalizado, vermelho se não
                              return Icon(
                                isCompleted ? Icons.check_circle : Icons.cancel,
                                color: isCompleted ? Colors.green : Colors.red, // Verde se finalizado
                              );
                            } else {
                              return const Icon(
                                Icons.cancel,
                                color: Colors.red, // Ícone de erro se não houver dados
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
