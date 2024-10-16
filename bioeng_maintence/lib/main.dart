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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String userName = 'Usuário'; // Variável para armazenar o nome do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _databaseReference.child('users/colaboradores').child(user.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        } else {
          userName = 'Usuário desconhecido';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        actions: [
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
                  const Icon(Icons.person, color: Colors.blueAccent),
                  const SizedBox(width: 5),
                  Text(
                    userName,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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

  Widget _buildSectionCard(String title, String description, List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0, // Removendo o sombreamento
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => InkWell(
                onTap: () {
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
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        FutureBuilder(
                          future: _databaseReference.child('setores/${item.toLowerCase().replaceAll(' ', '_')}').once(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasData) {
                              var data = snapshot.data as DatabaseEvent;
                              var finalizadoValue = data.snapshot.child('finalizado').value;
                              debugPrint('Valor recebido para $item: $finalizadoValue'); // Depuração
                              
                              bool isCompleted = false;
                              if (finalizadoValue is bool) {
                                isCompleted = finalizadoValue;
                              } else if (finalizadoValue is String) {
                                isCompleted = finalizadoValue.toLowerCase() == 'true';
                              }


                              return Icon(
                                isCompleted ? Icons.check_circle : Icons.cancel,
                                color: isCompleted ? Colors.green : Colors.red, // Verde se finalizado
                              );
                            } else {
                              return const Icon(
                                Icons.cancel,
                                color: Colors.red,
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
