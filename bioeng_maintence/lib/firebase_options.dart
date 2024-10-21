import 'package:firebase_core/firebase_core.dart'; // Importa a biblioteca Firebase para inicialização

/// Classe que fornece as opções padrão de configuração do Firebase.
class DefaultFirebaseOptions {
  // Função que retorna as opções de configuração para a plataforma atual (neste caso, FirebaseOptions para o projeto específico)
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      // Chave de API para autenticação e identificação do projeto Firebase
      apiKey: "AIzaSyDt-YgmhAmpCXrl5DIVx5Kc4kzLaibE-Rg",

      // Domínio de autenticação do Firebase
      authDomain: "eclin2-d3998.firebaseapp.com",

      // URL do Realtime Database do Firebase
      databaseURL: "https://eclin2-d3998-default-rtdb.firebaseio.com",

      // ID do projeto Firebase
      projectId: "eclin2-d3998",

      // Bucket de armazenamento para arquivos, imagens e outros dados
      storageBucket: "eclin2-d3998.appspot.com",

      // ID do remetente de mensagens do Firebase Cloud Messaging (FCM)
      messagingSenderId: "193880345460",

      // ID do aplicativo Firebase (único para a instância do aplicativo)
      appId: "1:193880345460:web:43e225185af9f18d1cfa21",

      // ID de medição usado para Firebase Analytics (se ativado)
      measurementId: "G-Q9WMGQYZPK"
    );
  }
}
