import 'package:bioeng_maintence/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signature/signature.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async'; // Importação para Timer
import 'package:intl/intl.dart'; // Para formatação da data e hora
import 'package:pdf/widgets.dart' as pw; // Pacote PDF
import 'package:printing/printing.dart'; // Pacote para salvar PDF

void main() {
  runApp(const CC1Page());
}

class CC1Page extends StatelessWidget {
  const CC1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final SignatureController _signatureController = SignatureController();
  final String _qrData = 'app://setor/cc1'; // QR code fixo apontando para o deep link CC1
  bool isCompleted = false; // Status de conclusão
  User? currentUser;
  String userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus(); // Carrega o status de conclusão
    _resetCompletionDaily(); // Reseta o status diariamente
    _loadUserData(); // Carrega o nome do colaborador logado
  }

  void _loadUserData() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _database
          .ref('users/colaboradores')
          .child(currentUser!.uid)
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName =
                event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CC1'), // Alterado para CC1
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Função de retorno para a página anterior
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deslogado com sucesso')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),
                (route) => false,
              ); // Retorna à página principal após logout
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code fixo:',
              style: TextStyle(fontSize: 18),
            ),
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context);
              },
              child: Center(
                child: QrImageView(
                  data: _qrData, // Gera QR Code com o deep link fixo
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!isCompleted) {
                  _openSignaturePopup(); // Abre o pop-up de assinatura
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'O setor já foi finalizado. Não é possível assinar.'),
                    ),
                  );
                }
              },
              child: const Text('Finalizar Ronda'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Status de Conclusão:',
              style: TextStyle(fontSize: 18),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Finalizado'),
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _openSignaturePopup(); // Abrir o pop-up de assinatura
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Exibe o QR Code em uma tela ampliada e dá a opção de salvar como PDF
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
              data: _qrData,
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveQRCodeAsPDF();
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
    final pdf = pw.Document();
    final qrImage = await QrPainter(
      data: _qrData,
      version: QrVersions.auto,
      gapless: false,
    ).toImageData(300); // Gera a imagem do QR Code

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
          );
        },
      ),
    );

    // Solicita para o usuário salvar o PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'qr_code_cc1.pdf',
    );
  }

  // Função para resetar o status de conclusão todo dia às 00:01
  void _resetCompletionDaily() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      var now = DateTime.now();
      if (now.hour == 0 && now.minute == 1) {
        _database.ref('setores/cc1').update({'finalizado': false});
        setState(() {
          isCompleted = false;
        });
      }
    });
  }

  // Pop-up para confirmar a assinatura e conclusão
  void _openSignaturePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assinatura'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _signatureController.clear();
                    },
                    child: const Text('Limpar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _saveCompletionStatus(); // Salvar assinatura e conclusão
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

  // Carrega o status de conclusão do setor
  void _loadCompletionStatus() {
    _database.ref('setores/cc1').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted =
              event.snapshot.child('finalizado').value as bool? ?? false;
        });
      }
    });
  }

  // Salva a assinatura, status de conclusão, data e horário no Firebase
  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        String dateTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        _database.ref('setores/cc1').set({
          'finalizado': true,
          'assinatura': signatureData,
          'data_hora': dateTime,
          'colaborador': userName,
        }).then((_) {
          setState(() {
            isCompleted = true;
          });
          Navigator.of(context).pop(); // Fechar o pop-up
        });
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }
}
