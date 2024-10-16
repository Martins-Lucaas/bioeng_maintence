import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:signature/signature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatação de data e hora
import 'package:qr_flutter/qr_flutter.dart'; // Para QR code
import 'package:pdf/widgets.dart' as pw; // Para geração de PDF
import 'package:printing/printing.dart'; // Para salvar o PDF

class GamaCamaraPage extends StatefulWidget {
  const GamaCamaraPage({super.key});

  @override
  State<GamaCamaraPage> createState() => _GamaCamaraPageState();
}

class _GamaCamaraPageState extends State<GamaCamaraPage> {
  bool isCompleted = false;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  String userName = 'Usuário';
  final String _qrData = 'app://setor/gama_camara'; // QR code fixo para deep link Gama Câmara

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus(); // Carregar status de finalização
    _loadUserData(); // Carregar nome do colaborador logado
  }

  // Função para carregar os dados do colaborador logado
  void _loadUserData() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _databaseReference
          .child('users/colaboradores')
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

  // Função para carregar o status de finalização do setor
  void _loadCompletionStatus() {
    _databaseReference.child('setores/gama_camara/finalizado').once().then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        setState(() {
          isCompleted = event.snapshot.value as bool? ?? false;
        });
      }
    });
  }

  // Abre o pop-up para assinatura
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
                      _saveCompletionStatus(); // Salvar status de conclusão e assinatura
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

  // Função para salvar o status de finalização e assinatura no Firebase
  void _saveCompletionStatus() async {
    if (_signatureController.isNotEmpty) {
      var signatureData = await _signatureController.toPngBytes();
      if (signatureData != null) {
        String dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        // Salva os dados no Firebase
        _databaseReference.child('setores/gama_camara').set({
          'finalizado': true,
          'assinatura': {
            'imagem': signatureData,  // Salva assinatura em formato PNG
          },
          'colaborador': userName, // Nome do colaborador que assinou
          'data_hora': dateTime, // Data e hora da assinatura
        }).then((_) {
          setState(() {
            isCompleted = true;
          });
          Navigator.of(context).pop(); // Fechar o pop-up
        });
      }
    }
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
      filename: 'qr_code_gama_camara.pdf',
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
        title: const Text('Gama Câmara'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Voltar para a página anterior
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _showQRCodeDialog(context); // Exibe o QR Code em tela cheia
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
                      content: Text('O setor já foi finalizado.'),
                    ),
                  );
                }
              },
              child: const Text('Finalizar Ronda'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Finalizado'),
                Checkbox(
                  value: isCompleted,
                  onChanged: (bool? value) {
                    if (value == true && !isCompleted) {
                      _openSignaturePopup(); // Abre o pop-up de assinatura
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
