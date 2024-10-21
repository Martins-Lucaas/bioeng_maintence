import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data'; // Para exibir a imagem da assinatura

class AdmMainPage extends StatefulWidget {
  const AdmMainPage({super.key});

  @override
  State<AdmMainPage> createState() => _AdmMainPageState();
}

class _AdmMainPageState extends State<AdmMainPage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  String userName = 'Administrador';
  Map<String, bool> setoresStatus = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenForDatabaseChanges();
  }

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

  void _listenForDatabaseChanges() {
    _databaseReference.child('setores').onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> setores = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          setoresStatus.clear();
          setores.forEach((key, value) {
            setoresStatus[key] = value['finalizado'] ?? false;
          });
        });
      }
    });
  }

  // Função para carregar os dados do setor e exibir no popup
  Future<void> _showSectorDetails(String setor) async {
    final snapshot = await _databaseReference.child('setores/$setor').once();
    if (snapshot.snapshot.exists) {
      Map setorData = snapshot.snapshot.value as Map;

      String colaborador = setorData['colaborador'] ?? 'N/A';
      String dataHora = setorData['data_hora'] ?? 'N/A';
      bool finalizado = setorData['finalizado'] == true;

      // Carregar assinatura como lista de inteiros (bytes)
      Uint8List? assinaturaBytes;
      if (setorData['assinatura'] != null && setorData['assinatura']['imagem'] != null) {
        assinaturaBytes = Uint8List.fromList(List<int>.from(setorData['assinatura']['imagem']));
      }

      // Verifica se o setor é "ressonancia_magnetica" e, se for, carrega a tabela
      List<TableRow> tableRows = [];
      if (setor == 'ressonancia_magnetica') {
        final tabelaSnapshot = await _databaseReference.child('setores/ressonancia_magnetica/tabela').once();
        if (tabelaSnapshot.snapshot.exists) {
          Map<dynamic, dynamic> tabelaData = tabelaSnapshot.snapshot.value as Map<dynamic, dynamic>;
          tabelaData.forEach((key, value) {
            final rowData = value as Map;
            tableRows.add(
              TableRow(
                children: [
                  Text('$key', textAlign: TextAlign.center),
                  Text('${rowData['nivelHelio'] ?? ''}', textAlign: TextAlign.center),
                  Text('${rowData['horimetro'] ?? ''}', textAlign: TextAlign.center),
                  Text('${rowData['pressao'] ?? ''}', textAlign: TextAlign.center),
                  Text('${rowData['temperatura'] ?? ''}', textAlign: TextAlign.center),
                  Text('${rowData['umidade'] ?? ''}', textAlign: TextAlign.center),
                ],
              ),
            );
          });
        }
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Setor: ${setor.replaceAll('_', ' ').toUpperCase()}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Colaborador: $colaborador'),
                  Text('Data/Hora: $dataHora'),
                  Text('Finalizado: ${finalizado ? "Sim" : "Não"}'),
                  const SizedBox(height: 10),
                  assinaturaBytes != null
                      ? Image.memory(assinaturaBytes) // Exibe a imagem da assinatura
                      : const Text('Sem assinatura disponível'), // Exibe uma mensagem se a assinatura não estiver disponível
                  const SizedBox(height: 20),
                  if (setor == 'ressonancia_magnetica') ...[
                    const Text('Tabela de Ressonância Magnética', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(),
                      columnWidths: const <int, TableColumnWidth>{
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                        4: FlexColumnWidth(2),
                        5: FlexColumnWidth(2),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Colors.grey),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('Linha', textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(8), child: Text('Nível de Hélio (%)', textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(8), child: Text('Horímetro (KHr)', textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(8), child: Text('Pressão (Psi)', textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(8), child: Text('Temperatura (ºC)', textAlign: TextAlign.center)),
                            Padding(padding: EdgeInsets.all(8), child: Text('Umidade (%)', textAlign: TextAlign.center)),
                          ],
                        ),
                        ...tableRows, // Exibe as linhas da tabela dinamicamente
                      ],
                    ),
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
      // Se não houver dados para o setor
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

  // Cancela a finalização individual de um setor
  void _cancelFinalization(String setor) {
    _databaseReference.child('setores/$setor').update({'finalizado': false});
  }

  // Função de logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Navega para a tela de login após o logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: const Text(
          'Painel de Administração',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout, // Ação para deslogar
        ),
        actions: [
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
          double horizontalPadding = constraints.maxWidth * 0.05; // 5% do tamanho da tela
          double fontSize = constraints.maxWidth * 0.04; // Tamanho relativo para o texto

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildSectionCard(
                  'Rondas Gerais',
                  'Verifique as rondas e controle suas finalizações.',
                  ['geral_area1', 'geral_area2', 'geral_area3'],
                  fontSize,
                ),
                const SizedBox(height: 20),
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

  // Função para criar um card de seção com os setores
  Widget _buildSectionCard(String title, String description, List<String> setores, double fontSize) {
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
              style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: fontSize, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...setores.map((setor) => _buildSetorItem(setor, fontSize)),
          ],
        ),
      ),
    );
  }

  // Função para criar o item de setor com botão para exibir popup de detalhes
  Widget _buildSetorItem(String setor, double fontSize) {
    bool isFinalizado = setoresStatus[setor] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => _showSectorDetails(setor), // Exibir pop-up ao clicar no setor
            child: Text(
              setor.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: Colors.blue),
            ),
          ),
          Row(
            children: [
              Icon(
                isFinalizado ? Icons.check_circle : Icons.cancel,
                color: isFinalizado ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _cancelFinalization(setor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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
