// =====================================================================
// ferramenta_service.dart
// ---------------------------------------------------------------------
// Camada do APP FLUTTER que conversa com a API PHP via HTTP.
// Fluxo: Tela Flutter -> este Service -> HTTP (JSON) -> ferramentas.php -> MySQL
//
// Pré-requisito no pubspec.yaml:
//   dependencies:
//     http: ^1.2.0
// Depois rode: flutter pub get
//
// ANDROID: adicione no AndroidManifest.xml a permissão
//   <uses-permission android:name="android.permission.INTERNET"/>
// e, como a API usa http (sem "s"), na tag <application>:
//   android:usesCleartextTraffic="true"
// =====================================================================

import 'dart:convert';                 // jsonEncode / jsonDecode
import 'package:http/http.dart' as http;

class FerramentaService {
  // IMPORTANTE:
  // - Emulador Android: "localhost" do PC é acessado por 10.0.2.2
  // - Celular físico: use o IP do PC na rede (ex.: 192.168.0.15)
  // - Flutter Web / iOS Simulator: localhost funciona
  static const String _baseUrl =
      'http://10.0.2.2/projeto_ferramentas/ferramentas.php';

  // Cabeçalho avisando a API que o corpo é JSON
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  // -------------------------------------------------------------------
  // POST -> cadastra uma ferramenta nova (vira INSERT no PHP)
  // Retorna o ID criado pelo banco.
  // -------------------------------------------------------------------
  Future<int> cadastrarFerramenta({
    required String nome,
    required String patrimonio,
    String status = 'disponivel',
    String? localizacao,
  }) async {
    final resposta = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      // Transforma o Map do Dart em texto JSON (é isso que o php://input lê)
      body: jsonEncode({
        'nome': nome,
        'patrimonio': patrimonio,
        'status': status,
        'localizacao': localizacao,
      }),
    );

    final corpo = jsonDecode(resposta.body); // texto JSON -> Map

    if (resposta.statusCode == 201) {
      return corpo['id'] as int;             // sucesso: devolve o ID gerado
    }
    // Qualquer outro código: lança erro com a mensagem vinda da API
    throw Exception(corpo['erro'] ?? 'Erro ao cadastrar ferramenta');
  }

  // -------------------------------------------------------------------
  // PUT -> altera uma ferramenta existente (vira UPDATE no PHP)
  // O id vai na URL; o corpo leva só os campos que queremos mudar.
  // -------------------------------------------------------------------
  Future<Map<String, dynamic>> atualizarFerramenta({
    required int id,
    String? status,
    String? localizacao,
  }) async {
    // Monta o JSON apenas com o que foi informado
    final dados = <String, dynamic>{};
    if (status != null) dados['status'] = status;
    if (localizacao != null) dados['localizacao'] = localizacao;

    final resposta = await http.put(
      Uri.parse('$_baseUrl?id=$id'),         // ex.: .../ferramentas.php?id=1
      headers: _headers,
      body: jsonEncode(dados),
    );

    final corpo = jsonDecode(resposta.body);

    if (resposta.statusCode == 200) {
      // Devolve a ferramenta já atualizada, como está no MySQL
      return corpo['ferramenta'] as Map<String, dynamic>;
    }
    throw Exception(corpo['erro'] ?? 'Erro ao atualizar ferramenta');
  }
}

// =====================================================================
// EXEMPLO DE USO (ex.: dentro do onPressed de um botão)
// =====================================================================
// final service = FerramentaService();
//
// // 1) Cadastro (POST)
// final novoId = await service.cadastrarFerramenta(
//   nome: 'Furadeira de Impacto',
//   patrimonio: 'FER-001',
//   localizacao: 'Almoxarifado A',
// );
//
// // 2) Mandar para manutenção (PUT)
// final atualizada = await service.atualizarFerramenta(
//   id: novoId,
//   status: 'em_manutencao',
//   localizacao: 'Oficina Central',
// );
// print(atualizada['status']); // em_manutencao
