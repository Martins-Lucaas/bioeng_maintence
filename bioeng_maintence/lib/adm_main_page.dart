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

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Setor: ${setor.replaceAll('_', ' ').toUpperCase()}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Colaborador: $colaborador'),
                Text('Data/Hora: $dataHora'),
                Text('Finalizado: ${finalizado ? "Sim" : "Não"}'),
                const SizedBox(height: 10),
                assinaturaBytes != null
                    ? Image.memory(assinaturaBytes) // Exibe a imagem da assinatura
                    : const Text('Sem assinatura disponível'), // Exibe uma mensagem se a assinatura não estiver disponível
              ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildSectionCard('Rondas Gerais', 'Verifique as rondas e controle suas finalizações.', [
              'geral_area1',
              'geral_area2',
              'geral_area3',
            ]),
            const SizedBox(height: 20),
            _buildSectionCard('Inspeções', 'Controle as inspeções e suas finalizações.', [
              'hemodinamica_subsolo',
              'hemodinamica_cc',
              'gama_camara',
              'ressonancia_magnetica',
              'tomografo_toshiba',
              'tomografo_siemens_oncologia',
              'tomografo_siemens_subsolo',
              'osmose_fixa01',
              'osmose_fixa02',
            ]),
            const SizedBox(height: 20),
            _buildSectionCard('Rondas Setoriais', 'Gerencie rondas setoriais e suas finalizações.', [
              'cme',
              'cme2',
              'pronto_socorro',
              'uti',
              'cc1',
              'cc2',
            ]),
          ],
        ),
      ),
    );
  }

  // Função para criar um card de seção com os setores
  Widget _buildSectionCard(String title, String description, List<String> setores) {
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
            ...setores.map((setor) => _buildSetorItem(setor)),
          ],
        ),
      ),
    );
  }

  // Função para criar o item de setor com botão para exibir popup de detalhes
  Widget _buildSetorItem(String setor) {
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue),
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
                child: const Text('Cancelar Finalização'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
