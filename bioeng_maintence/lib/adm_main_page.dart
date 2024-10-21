import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data'; // Importação para manipular dados binários (exibição da imagem da assinatura)
import 'package:bioeng_maintence/login_page.dart';  // Importa a página de login

// Página principal para o administrador
class AdmMainPage extends StatefulWidget {
  const AdmMainPage({super.key});

  @override
  State<AdmMainPage> createState() => _AdmMainPageState();
}

class _AdmMainPageState extends State<AdmMainPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref(); // Referência ao Realtime Database do Firebase
  String userName = 'Administrador'; // Nome do usuário administrador exibido no topo da página
  Map<String, bool> setoresStatus = {}; // Armazena o status de finalização de cada setor

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carrega os dados do usuário ao iniciar a página
    _listenForDatabaseChanges(); // Escuta alterações no banco de dados em tempo real
  }

  // Função para carregar o nome do administrador do Firebase
  void _loadUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _databaseReference.child('users/administradores').child(user.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Administrador';
          });
        } else {
          userName = 'Administrador desconhecido';
        }
      });
    }
  }

  // Função que escuta as mudanças no status dos setores em tempo real
  void _listenForDatabaseChanges() {
    _databaseReference.child('setores').onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> setores = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          setoresStatus.clear();
          setores.forEach((key, value) {
            setoresStatus[key] = value['finalizado'] ?? false; // Atualiza o status de finalização de cada setor
          });
        });
      }
    });
  }

  // Função que exibe os detalhes de um setor em um pop-up (incluindo a assinatura, se houver)
  Future<void> _showSectorDetails(String setor) async {
    final snapshot = await _databaseReference.child('setores/$setor').once();

    if (snapshot.snapshot.exists) {
      Map setorData = snapshot.snapshot.value as Map;

      String colaborador = setorData['colaborador'] ?? 'N/A'; // Nome do colaborador responsável
      String dataHora = setorData['data_hora'] ?? 'N/A'; // Data e hora da finalização
      bool finalizado = setorData['finalizado'] == true; // Status de finalização

      // Carrega a assinatura, se disponível
      Uint8List? assinaturaBytes;
      if (setorData['assinatura'] != null && setorData['assinatura']['imagem'] != null) {
        assinaturaBytes = Uint8List.fromList(List<int>.from(setorData['assinatura']['imagem']));
      }

      List<Widget> planilhaRows = [];
      // Verifica se o setor é "ressonância magnética" e carrega os dados da tabela
      if (setor == 'ressonancia_magnetica') {
        final tabelaSnapshot = await _databaseReference.child('setores/ressonancia_magnetica/tabela').once();

        if (tabelaSnapshot.snapshot.exists) {
          Map<dynamic, dynamic> tabelaData = tabelaSnapshot.snapshot.value as Map<dynamic, dynamic>;

          // Gera as linhas com os dados da planilha
          tabelaData.forEach((key, value) {
            final rowData = value as Map;
            String dataFinalizacao = rowData['data_hora'] ?? 'Data não disponível';

            planilhaRows.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data de Finalização: $dataFinalizacao', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Nível de Hélio (%): ${rowData['nivelHelio'] ?? 'N/A'}'),
                    Text('Horímetro (KHr): ${rowData['horimetro'] ?? 'N/A'}'),
                    Text('Pressão (Psi): ${rowData['pressao'] ?? 'N/A'}'),
                    Text('Temperatura (ºC): ${rowData['temperatura'] ?? 'N/A'}'),
                    Text('Umidade (%): ${rowData['umidade'] ?? 'N/A'}'),
                    const Divider(),
                  ],
                ),
              ),
            );
          });
        }
      }

      // Exibe o pop-up com as informações do setor
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Setor: ${setor.replaceAll('_', ' ').toUpperCase()}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colaborador: $colaborador'),
                  Text('Data/Hora: $dataHora'),
                  Text('Finalizado: ${finalizado ? "Sim" : "Não"}'),
                  const SizedBox(height: 10),
                  assinaturaBytes != null
                      ? Image.memory(assinaturaBytes) // Exibe a assinatura, se disponível
                      : const Text('Sem assinatura disponível'),
                  const SizedBox(height: 20),
                  if (setor == 'ressonancia_magnetica') ...[
                    const Text('Dados da Ressonância Magnética', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...planilhaRows,
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } else {
      // Exibe um pop-up de erro caso não haja dados disponíveis para o setor
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Nenhum dado encontrado para este setor.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    }
  }

  // Função para cancelar a finalização de um setor
  void _cancelFinalization(String setor) {
    _databaseReference.child('setores/$setor').update({'finalizado': false});
  }

  // Função de logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Desconecta o usuário do Firebase

    // Redireciona para a página de login após o logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0, // Remove a sombra do AppBar
        title: const Text(
          'Painel de Administração',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true, // Centraliza o título no AppBar
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout, // Ação para deslogar
        ),
        actions: [
          // Exibe o nome do usuário no canto superior direito
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          double horizontalPadding = constraints.maxWidth * 0.05; // Define o padding horizontal
          double fontSize = constraints.maxWidth * 0.04; // Define o tamanho da fonte com base na largura da tela

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Seção de Rondas Gerais
                _buildSectionCard(
                  'Rondas Gerais',
                  'Verifique as rondas e controle suas finalizações.',
                  ['geral_area1', 'geral_area2', 'geral_area3'],
                  fontSize,
                ),
                const SizedBox(height: 20),
                // Seção de Inspeções
                _buildSectionCard(
                  'Inspeções',
                  'Controle as inspeções e suas finalizações.',
                  [
                    'hemodinamica_subsolo',
                    'hemodinamica_cc',
                    'gama_camara',
                    'ressonancia_magnetica',
                    'tomografo_toshiba',
                    'tomografo_siemens_oncologia',
                    'tomografo_siemens_subsolo',
                    'osmose_fixa01',
                    'osmose_fixa02',
                  ],
                  fontSize,
                ),
                const SizedBox(height: 20),
                // Seção de Rondas Setoriais
                _buildSectionCard(
                  'Rondas Setoriais',
                  'Gerencie rondas setoriais e suas finalizações.',
                  ['cme', 'cme2', 'pronto_socorro', 'uti', 'cc1', 'cc2'],
                  fontSize,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Função para construir os cartões de cada seção
  Widget _buildSectionCard(String title, String description, List<String> setores, double fontSize) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 5, // Sombra do cartão
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, // Título da seção
              style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description, // Descrição da seção
              style: TextStyle(fontSize: fontSize, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            // Para cada setor, cria um item na lista
            ...setores.map((setor) => _buildSetorItem(setor, fontSize)),
          ],
        ),
      ),
    );
  }

  // Função para construir o item de cada setor com o botão de cancelar a finalização
  Widget _buildSetorItem(String setor, double fontSize) {
    bool isFinalizado = setoresStatus[setor] ?? false; // Verifica se o setor está finalizado

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _showSectorDetails(setor), // Ao clicar, exibe os detalhes do setor
            child: Text(
              setor.replaceAll('_', ' ').toUpperCase(), // Formata o nome do setor para exibição
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
          ),
          Row(
            children: [
              // Exibe um ícone de check se finalizado, ou um ícone de cancel se não finalizado
              Icon(
                isFinalizado ? Icons.check_circle : Icons.cancel,
                color: isFinalizado ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              // Botão para cancelar a finalização do setor
              ElevatedButton(
                onPressed: () => _cancelFinalization(setor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Cor vermelha do botão
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Cancelar Finalização', style: TextStyle(fontSize: fontSize * 0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
