import 'package:bioeng_maintence/main.dart'; // Importa a página principal do app
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Biblioteca do Firebase para Realtime Database
import 'package:firebase_auth/firebase_auth.dart'; // Biblioteca do Firebase para autenticação
import 'package:signature/signature.dart'; // Biblioteca para captura de assinaturas digitais
import 'package:qr_flutter/qr_flutter.dart'; // Biblioteca para geração de QR Codes
import 'dart:async'; // Biblioteca para Timer e funções assíncronas
import 'package:intl/intl.dart'; // Biblioteca para formatação de datas
import 'package:pdf/widgets.dart' as pw; // Biblioteca para manipulação de PDFs
import 'package:printing/printing.dart'; // Biblioteca para salvar/compartilhar PDFs

class CC1Page extends StatelessWidget {
  const CC1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // Define a página inicial
    );
  }
}

// Página Home para o setor CC1
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instância do FirebaseAuth para autenticação
  final FirebaseDatabase _database = FirebaseDatabase.instance; // Instância do Realtime Database
  final SignatureController _signatureController = SignatureController(); // Controlador de assinatura
  final String _qrData = 'app://setor/cc1'; // Dados do QR Code para deep link
  bool isCompleted = false; // Status de finalização
  User? currentUser;
  String userName = 'Usuário'; // Nome do colaborador logado

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus(); // Carrega o status de conclusão
    _loadUserData(); // Carrega os dados do usuário
  }

  // Função para carregar os dados do colaborador logado
  void _loadUserData() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _database.ref('users/colaboradores').child(currentUser!.uid).once().then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        }
      });
    }
  }

  // Função para carregar o status de conclusão do setor
  void _loadCompletionStatus() {
    _database.ref('setores/cc1/finalizado').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.value as bool? ?? false;
        });
      }
    });
  }

  // TABELA AQUI //
  // FUNCIONAMENTO:
  // A tabela pode ser implementada aqui usando o widget `Table` do Flutter.
  // Você pode usar o widget `TableRow` para definir as linhas da tabela.
  // As células da tabela podem ser editáveis, usando `TextFormField` para permitir a entrada de dados.

  // CELULAS EDITÁVEIS:
  // Para as células editáveis, você pode usar `TextFormField` dentro de cada célula.
  // As células podem ser habilitadas ou desabilitadas com base no status de finalização da linha.
  // Exemplo de célula editável:
  // `TextFormField` que captura dados como "Nível de Oxigênio", "Temperatura", etc.
  // O dado é salvo automaticamente no Firebase após ser editado.

  // ADICIONAR NOVA LINHA:
  // Ao final da tabela, você pode adicionar uma nova linha editável.
  // Essa nova linha pode permitir ao usuário inserir novos dados e salvá-los diretamente no Firebase.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CC1'), // Título da página
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone de voltar
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Home')), // Retorna para a página principal
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Espaçamento da página
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TABELA AQUI //
            // INSERIR A TABELA NESTA SEÇÃO //
            // Essa tabela deve conter as colunas como "Nível de Oxigênio", "Temperatura", "Pressão", etc.
            // As linhas podem ser geradas dinamicamente a partir dos dados do Firebase.
            
            // Tabela com as colunas: "Nível de Oxigênio", "Temperatura", "Pressão", "Umidade"
            // Cada célula da tabela deve ser um `TextFormField` que permite ao usuário editar e salvar automaticamente as informações.

            const SizedBox(height: 20), // Espaçamento

            // Botão para finalizar a ronda
            ElevatedButton(
              onPressed: () {
                if (!isCompleted) {
                  _openSignaturePopup(); // Abre o pop-up de assinatura
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('O setor já foi finalizado. Não é possível assinar.'),
                    ),
                  );
                }
              },
              child: const Text('Finalizar Ronda'),
            ),
            const SizedBox(height: 20), // Espaçamento
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context); // Exibe o QR Code em uma tela ampliada
              },
              child: Center(
                child: QrImageView(
                  data: _qrData, // Dados do QR code (deep link)
                  version: QrVersions.auto,
                  size: 200.0, // Tamanho do QR code
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Exibe o QR Code ampliado e permite salvar como PDF
  void _showQRCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: _qrData, // Dados do QR code
              version: QrVersions.auto,
              size: 300.0, // Tamanho do QR code
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveQRCodeAsPDF(); // Salva o QR code como PDF
              },
              child: const Text('Salvar como PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o pop-up
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Função para salvar o QR Code como PDF
  Future<void> _saveQRCodeAsPDF() async {
    final pdf = pw.Document(); // Cria um documento PDF
    final qrImage = await QrPainter(
      data: _qrData, // Dados do QR code
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300); // Gera a imagem do QR code

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())), // Adiciona o QR code ao PDF
          );
        },
      ),
    );

    // Solicita para o usuário salvar o PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'qr_code_cc1.pdf', // Nome do arquivo PDF
    );
  }

  // Função para abrir o pop-up de assinatura
  void _openSignaturePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assinatura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Widget de captura de assinatura
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Borda da área de assinatura
                ),
                child: Signature(
                  controller: _signatureController, // Controlador da assinatura
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _signatureController.clear(); // Limpa a assinatura
                    },
                    child: const Text('Limpar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _saveCompletionStatus(); // Salva a assinatura e finaliza a ronda
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Função que salva a assinatura e finaliza o setor no Firebase
  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes(); // Obtém a assinatura como PNG
      if (signatureData != null) {
        String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()); // Data e hora atuais

        _database.ref('setores/cc1').set({
          'finalizado': true, // Marca o setor como finalizado
          'assinatura': {
            'imagem': signatureData, // Salva a assinatura como imagem
          },
          'data_hora': dateTime, // Salva a data e hora da assinatura
          'colaborador': userName, // Nome do colaborador
        }).then((_) {
          setState(() {
            isCompleted = true; // Atualiza o status de conclusão
          });
          Navigator.of(context).pop(); // Fecha o pop-up de assinatura
        });
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose(); // Limpa o controlador de assinatura ao fechar a página
    super.dispose();
  }
}
