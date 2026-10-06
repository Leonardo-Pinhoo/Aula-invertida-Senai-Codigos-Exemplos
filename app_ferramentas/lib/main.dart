// =====================================================================
// main.dart
// ---------------------------------------------------------------------
// Tela única do app: lista as ferramentas (GET), cadastra uma nova
// (POST) e altera o status/localização de uma existente (PUT).
// Toda a comunicação com a API fica no FerramentaService.
// =====================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import 'ferramenta_service.dart';

void main() => runApp(const AppFerramentas());

class AppFerramentas extends StatelessWidget {
  const AppFerramentas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Ferramentas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const TelaFerramentas(),
    );
  }
}

// Status aceitos pela API (iguais ao ENUM do banco) e o texto mostrado na tela
const Map<String, String> rotulosStatus = {
  'disponivel': 'Disponível',
  'emprestada': 'Emprestada',
  'em_manutencao': 'Em manutenção',
};

const Map<String, Color> coresStatus = {
  'disponivel': Colors.green,
  'emprestada': Colors.orange,
  'em_manutencao': Colors.red,
};

class TelaFerramentas extends StatefulWidget {
  const TelaFerramentas({super.key});

  @override
  State<TelaFerramentas> createState() => _TelaFerramentasState();
}

class _TelaFerramentasState extends State<TelaFerramentas> {
  final _service = FerramentaService();
  List<Map<String, dynamic>> _ferramentas = [];
  bool _carregando = true;
  String? _erro;

  // Atualização automática: a cada 3 segundos o app pergunta à API se a
  // lista mudou. Assim o que for cadastrado em um tablet aparece no outro.
  Timer? _timer;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _carregar(silencioso: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // GET: busca a lista no MySQL através da API.
  // No modo silencioso (atualização automática) não mostra o "carregando".
  Future<void> _carregar({bool silencioso = false}) async {
    if (_buscando) return; // evita duas buscas ao mesmo tempo
    _buscando = true;
    if (!silencioso) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final lista = await _service.listarFerramentas();
      if (!mounted) return;
      setState(() {
        _ferramentas = lista;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = _mensagem(e));
    } finally {
      _buscando = false;
      if (mounted && !silencioso) setState(() => _carregando = false);
    }
  }

  // Tira o "Exception: " do começo da mensagem para mostrar ao usuário
  String _mensagem(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _avisar(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red.shade700 : null,
      ),
    );
  }

  // POST: abre o formulário de cadastro
  Future<void> _abrirCadastro() async {
    final dados = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => const DialogoCadastro(),
    );
    if (dados == null) return;

    try {
      final id = await _service.cadastrarFerramenta(
        nome: dados['nome']!,
        patrimonio: dados['patrimonio']!,
        status: dados['status']!,
        localizacao: dados['localizacao'],
      );
      _avisar('Ferramenta cadastrada com o id $id');
      _carregar();
    } catch (e) {
      _avisar(_mensagem(e), erro: true);
    }
  }

  // PUT: abre o formulário de alteração de uma ferramenta
  Future<void> _abrirAlteracao(Map<String, dynamic> ferramenta) async {
    final dados = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => DialogoAlteracao(ferramenta: ferramenta),
    );
    if (dados == null) return;

    try {
      // O PHP devolve o id como texto ("1"), por isso o int.parse
      final atualizada = await _service.atualizarFerramenta(
        id: int.parse('${ferramenta['id']}'),
        status: dados['status'],
        localizacao: dados['localizacao'],
      );
      _avisar('"${atualizada['nome']}" atualizada');
      _carregar();
    } catch (e) {
      _avisar(_mensagem(e), erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Ferramentas'),
        actions: [
          IconButton(
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add),
        label: const Text('Nova ferramenta'),
      ),
      body: RefreshIndicator(onRefresh: _carregar, child: _corpo()),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Não foi possível acessar a API',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_erro!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _carregar,
              child: const Text('Tentar de novo'),
            ),
          ),
        ],
      );
    }
    if (_ferramentas.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          Icon(Icons.handyman_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma ferramenta cadastrada.\nToque em "Nova ferramenta".',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _ferramentas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = _ferramentas[i];
        final status = '${f['status']}';
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${f['id']}')),
            title: Text('${f['nome']}'),
            subtitle: Text(
              'Patrimônio: ${f['patrimonio']}\n'
              'Local: ${f['localizacao'] ?? '—'}',
            ),
            isThreeLine: true,
            trailing: Chip(
              label: Text(rotulosStatus[status] ?? status),
              side: BorderSide(color: coresStatus[status] ?? Colors.grey),
            ),
            onTap: () => _abrirAlteracao(f),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Formulário do POST (cadastro)
// ---------------------------------------------------------------------
class DialogoCadastro extends StatefulWidget {
  const DialogoCadastro({super.key});

  @override
  State<DialogoCadastro> createState() => _DialogoCadastroState();
}

class _DialogoCadastroState extends State<DialogoCadastro> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _patrimonio = TextEditingController();
  final _localizacao = TextEditingController();
  String _status = 'disponivel';

  @override
  void dispose() {
    _nome.dispose();
    _patrimonio.dispose();
    _localizacao.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final local = _localizacao.text.trim();
    Navigator.pop(context, {
      'nome': _nome.text.trim(),
      'patrimonio': _patrimonio.text.trim(),
      'status': _status,
      'localizacao': local.isEmpty ? null : local,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova ferramenta (POST)'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome *'),
                  validator: _obrigatorio,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: _patrimonio,
                  decoration: const InputDecoration(
                    labelText: 'Patrimônio *',
                    hintText: 'ex.: FER-001',
                  ),
                  validator: _obrigatorio,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: _localizacao,
                  decoration: const InputDecoration(labelText: 'Localização'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final s in rotulosStatus.entries)
                      DropdownMenuItem(value: s.key, child: Text(s.value)),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _salvar, child: const Text('Cadastrar')),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Formulário do PUT (alteração de status e localização)
// ---------------------------------------------------------------------
class DialogoAlteracao extends StatefulWidget {
  const DialogoAlteracao({super.key, required this.ferramenta});

  final Map<String, dynamic> ferramenta;

  @override
  State<DialogoAlteracao> createState() => _DialogoAlteracaoState();
}

class _DialogoAlteracaoState extends State<DialogoAlteracao> {
  late String _status = '${widget.ferramenta['status']}';
  late final _localizacao =
      TextEditingController(text: widget.ferramenta['localizacao'] ?? '');

  @override
  void dispose() {
    _localizacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Alterar "${widget.ferramenta['nome']}" (PUT)'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in rotulosStatus.entries)
                  DropdownMenuItem(value: s.key, child: Text(s.value)),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            TextFormField(
              controller: _localizacao,
              decoration: const InputDecoration(labelText: 'Localização'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'status': _status,
            'localizacao': _localizacao.text.trim(),
          }),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
