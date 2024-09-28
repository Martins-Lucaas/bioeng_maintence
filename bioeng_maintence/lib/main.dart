// Importa os pacotes necessários.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:firebase_database/firebase_database.dart';

// Função principal que inicializa o aplicativo.
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que os widgets do Flutter estejam vinculados.
  await Firebase.initializeApp( // Inicializa o Firebase com as opções atuais da plataforma.
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp()); // Executa o aplicativo.
}

// Classe principal do aplicativo.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Define o tema do aplicativo.
        useMaterial3: true,
      ),
      home: const LoginPage(), // Define a página inicial como a página de login.
    );
  }
}

// Classe para a página inicial do aplicativo.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Estado da classe MyHomePage.
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // Inicializa um contador.
  Map<String, dynamic>? _userData; // Armazena os dados do usuário.

  // Referência ao banco de dados do Firebase.
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carrega os dados do usuário ao inicializar o estado.
  }

  // Método para carregar os dados do usuário.
  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser; // Obtém o usuário atual.
    if (user != null) {
      // Primeiro, verifica se o usuário está no nó 'medicos'.
      DatabaseReference userRef = _databaseReference.child('users/medicos').child(user.uid);
      userRef.once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          // Usuário encontrado no nó 'medicos'.
          setState(() {
            _userData = Map<String, dynamic>.from(event.snapshot.value as Map);
            _userData!['userType'] = 'Médico'; // Adiciona o tipo de usuário manualmente.
            _counter = _userData!['counter'] ?? 0; // Carrega o contador do banco de dados.
          });
        } else {
          // Se não for encontrado em 'medicos', verifica em 'pacientes'.
          userRef = _databaseReference.child('users/pacientes').child(user.uid);
          userRef.once().then((DatabaseEvent event) {
            if (event.snapshot.exists) {
              // Usuário encontrado no nó 'pacientes'.
              setState(() {
                _userData = Map<String, dynamic>.from(event.snapshot.value as Map);
                _userData!['userType'] = 'Paciente'; // Adiciona o tipo de usuário manualmente.
                _counter = _userData!['counter'] ?? 0; // Carrega o contador do banco de dados.
              });
            }
          });
        }
      });
    }
  }

  // Método para incrementar o contador.
  void _incrementCounter() {
    if (_userData != null) {
      setState(() {
        _counter++; // Incrementa o contador.
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Atualiza o valor do contador no banco de dados para o usuário específico.
          String userType = _userData!['userType'] == 'Médico' ? 'medicos' : 'pacientes';
          _databaseReference.child('users').child(userType).child(user.uid).update({
            'counter': _counter,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title), // Define o título do AppBar.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone de voltar.
          onPressed: () {
            // Volta para a página de login e remove todas as rotas anteriores.
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Exibe as informações do usuário ou uma mensagem de carregando.
            if (_userData != null) ...[
              Text(
                'Nome: ${_userData!['name']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'E-mail: ${_userData!['email']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                'Tipo de Usuário: ${_userData!['userType']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_userData!['userType'] == 'Médico') // Exibe o CRM se o usuário for médico.
                Text(
                  'CRM: ${_userData!['crm'] ?? 'N/A'}', // Verifica se o CRM existe.
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              Text(
                'Data de Nascimento: ${_userData!['dateOfBirth']}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ] else ...[
              const Text('Carregando informações do usuário...'),
            ],
            const SizedBox(height: 20),
            const Text(
              'Você pressionou o botão esta quantidade de vezes:',
            ),
            Text(
              '$_counter', // Exibe o valor do contador.
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      // Botão flutuante para incrementar o contador.
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter, // Chama o método de incrementar ao pressionar.
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
