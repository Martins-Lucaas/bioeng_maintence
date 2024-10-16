import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CC2Page extends StatefulWidget {
  const CC2Page({super.key});

  @override
  State<CC2Page> createState() => _CC2PageState();
}

class _CC2PageState extends State<CC2Page> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );
  final String _qrData = 'app://setor/cc2'; // QR code fixo para deep link
  String userName = 'Usuário';

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
    _loadUserData();
  }

  void _loadUserData() {
    // Carrega o nome do usuário logado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _databaseReference
          .child('users/colaboradores')
          .child(currentUser.uid)
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            userName = event.snapshot.child('name').value as String? ?? 'Usuário';
          });
        }
      });
    }
  }

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
                      _signatureController.clear(); // Limpar assinatura
                    },
                    child: const Text('Limpar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _saveCompletionStatus();
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

  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        _databaseReference.child('setores/cc2').set({
          'finalizado': true,
          'assinatura': {
            'imagem': signatureData,  // Assinatura em PNG
          },
          'colaborador': userName,
          'data_hora': dateTime,
        }).then((_) {
          setState(() {
            isCompleted = true;
          });
          Navigator.of(context).pop(); // Fechar o pop-up
        });
      }
    }
  }

  void _loadCompletionStatus() {
    _databaseReference.child('setores/cc2/finalizado').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.value as bool? ?? false;
        });
      }
    });
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
              data: _qrData,  // Gera o QR code com a URL armazenada em _qrData
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _saveQRCodeAsPDF();  // Função para salvar o QR code como PDF
              },
              child: const Text('Salvar como PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();  // Fecha o pop-up
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
      filename: 'qr_code_cc2.pdf',
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CC2'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context);  // Exibe o QR Code em tela cheia
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
                      content: Text('O setor já foi finalizado. Não é possível assinar.'),
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
}
