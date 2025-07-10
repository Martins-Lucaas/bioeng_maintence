# bioeng\_maintence

Este repositório contém o aplicativo **Engenharia Clínica 2**, desenvolvido em Flutter, que gerencia rondas e inspeções de setores hospitalares utilizando **Firebase Auth** e **Realtime Database**.

---

## Funcionalidades

* **Autenticação**: login/logout via Firebase Auth (administrador e colaborador).
* **Cadastro de usuários**: criação de contas de administradores e colaboradores.
* **Listagem de setores**: visualização do status de cada setor (finalizado/não finalizado).
* **Finalização de setor**: colaboradores podem finalizar um setor e registrar assinatura digital.
* **Assinatura digital**: captura de assinatura com o widget `Signature` e armazenamento em PNG.
* **Geração de QR Code**: criação de QR Code para cada setor, com opção de salvar como PDF.
* **Cancelamento de finalização**: administradores podem reverter o status de finalização de setores.
* **Perfil de usuário**: exibição de informações básicas do colaborador.

---

## Pré-requisitos

* Flutter SDK (2.10+)
* Dart SDK
* Conta no Firebase com projeto configurado
* Ferramentas:

  * Android Studio / VS Code
  * Emulador Android / dispositivo físico

---

## Instalando e executando

1. **Clone o repositório**:

   ```bash
   git clone https://github.com/seu-usuario/bioeng_maintence.git
   cd bioeng_maintence
   cd engenharia-clinica-2
   ```

2. **Obtenha as dependências**:

   ```bash
   flutter pub get
   ```

3. **Configuração do Firebase**:

   * Copie o arquivo `firebase_options.dart` (fornecido pelo Firebase CLI) para a pasta `lib/`.
   * Verifique em `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` se estão presentes.

4. **Execute o app**:

   ```bash
   flutter run
   ```

---

## Estrutura do Projeto

```plaintext
lib/
├─ main.dart           # Entrada do app e inicialização do Firebase
├─ firebase_options.dart  # Configuração do Firebase
├─ login_page.dart      # Tela de login
├─ register_page.dart   # Tela de cadastro de usuários
├─ adm_main_page.dart   # Tela principal para administradores
├─ views/
│   ├─ cc1.dart         # Página do setor CC1
│   ├─ cc2.dart         # Página do setor CC2
│   ├─ cme.dart         # Página do setor CME
│   └─ cme2.dart        # Página do setor CME2
└─ ...                 # Outros arquivos de apoio
```

---

## Como funciona

1. **Login**: o usuário insere e-mail e senha. Se autenticado:

   * Administrador é redirecionado para **AdmMainPage**.
   * Colaborador é redirecionado à lista de setores.

2. **AdmMainPage**:

   * Visualiza todos os setores e seus status.
   * Pode cancelar a finalização de qualquer setor.

3. **Setor Page** (ex.: CC1Page):

   * Exibe tabela de medições específicas do setor.
   * Botão **Finalizar**: marca o setor como concluído.
   * Botão **Assinar**: captura assinatura digital e armazena data/hora e colaborador.
   * Botão **QR Code**: gera código para o setor e permite salvar em PDF.

4. **Cancelamento**: apenas administradores podem reverter o status de finalização.

5. **Logout**: encerra sessão via FirebaseAuth e retorna à tela de login.

---

## Padrão de Arquitetura

Este projeto pode ser organizado em **MVVM** ou **BLoC**:

* **MVVM**: utiliza `ChangeNotifier` + `Provider` para expor estados de `ViewModel` às páginas.
* **BLoC**: define `Events` e `States` para cada fluxo (autenticação, setores, assinatura).

Escolha o padrão de acordo com a complexidade e necessidade de testes do seu time.

---

## Contribuindo

1. Faça um *fork* deste repositório.
2. Crie uma branch com sua feature: `git checkout -b feature/nome-da-feature`.
3. Commit suas alterações: `git commit -m 'Adiciona feature X'`.
4. Envie para o branch: `git push origin feature/nome-da-feature`.
5. Abra um *Pull Request*.

---

## Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
