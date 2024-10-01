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
  bool _showSetores = false;
  String userName = 'Usuário'; // Variável para armazenar o nome do usuário

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Busca o nome do usuário do Firebase (colaboradores ou administradores)
      _databaseReference.child('colaboradores').child(user.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        } else {
          _databaseReference.child('administradores').child(user.uid).once().then((DatabaseEvent event) {
            if (event.snapshot.exists) {
              setState(() {
                userName = event.snapshot.child('name').value as String? ?? 'Usuário';
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showSetores = !_showSetores;
                  });
                },
                child: const Text('Selecione o setor'),
              ),
              const SizedBox(height: 20),
              _showSetores ? _buildSetoresSection() : Container(),
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
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, String description, List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
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
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
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
                          bool isCompleted = data.snapshot.child('finalizado').value as bool? ?? false;
                          String? assinatura = data.snapshot.child('assinatura').value as String?;

                          return Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.cancel,
                                color: isCompleted ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCompleted
                                    ? 'Concluído por: $assinatura'
                                    : 'Não concluído',
                                style: TextStyle(
                                  color: isCompleted ? Colors.green : Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const Text(
                            'Não concluído',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetoresSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Setores Disponíveis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            buildSetores(),
          ],
        ),
      ),
    );
  }

  Widget buildSetores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSection('Ronda Geral', [
          'Geral Área 1',
          'Geral Área 2',
          'Geral Área 3',
        ]),
        const SizedBox(height: 20),
        buildSection('Inspeção', [
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
        buildSection('Ronda Setorial', [
          'CME',
          'CME 2',
          'Pronto Socorro',
          'UTI',
          'CC 1',
          'CC 2',
        ]),
      ],
    );
  }

  Widget buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => GestureDetector(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FutureBuilder(
                    future: _databaseReference.child('setores/${item.toLowerCase().replaceAll(' ', '_')}').once(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasData) {
                        var data = snapshot.data as DatabaseEvent;
                        bool isCompleted = data.snapshot.child('finalizado').value as bool? ?? false;
                        return Icon(
                          isCompleted ? Icons.check_circle : Icons.cancel,
                          color: isCompleted ? Colors.green : Colors.red,
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
      ],
    );
  }
}
