import 'package:firebase_core/firebase_core.dart';

/// Classe que fornece as opções padrão de configuração do Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyDt-YgmhAmpCXrl5DIVx5Kc4kzLaibE-Rg",
      authDomain: "eclin2-d3998.firebaseapp.com",
      databaseURL: "https://eclin2-d3998-default-rtdb.firebaseio.com",
      projectId: "eclin2-d3998",
      storageBucket: "eclin2-d3998.appspot.com",
      messagingSenderId: "193880345460",
      appId: "1:193880345460:web:43e225185af9f18d1cfa21",
      measurementId: "G-Q9WMGQYZPK"
    );
  }
}
