import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlunosPage extends StatefulWidget {
  const AlunosPage({super.key});

  @override
  State<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends State<AlunosPage> {
  final _supabase = Supabase.instance.client;
  final _nomeController = TextEditingController();
  final _matriculaController = TextEditingController();
  String? _selectedTurmaId;
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _turmas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final turRes = await _supabase.from('turmas').select().order('nome');
      final aluRes = await _supabase.from('alunos').select().order('nome');
      setState(() {
        _turmas = List<Map<String, dynamic>>.from(turRes);
        _alunos = List<Map<String, dynamic>>.from(aluRes);
      });
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addAluno() async {
    if (_nomeController.text.isEmpty || _selectedTurmaId == null) {
       _showError('Preencha o nome e selecione uma turma');
       return;
    }
    try {
      await _supabase.from('alunos').insert({
        'nome': _nomeController.text,
        'matricula': _matriculaController.text,
        'turma_id': _selectedTurmaId,
      });
      _nomeController.clear();
      _matriculaController.clear();
      if (mounted) Navigator.pop(context);
      _loadData();
    } catch (e) {
      _showError('Erro ao adicionar: $e');
    }
  }

  void _showAddDialog() {
    if (_turmas.isEmpty) {
      _showError('Cadastre uma turma antes de adicionar alunos!');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo Aluno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _matriculaController,
                decoration: const InputDecoration(labelText: 'Nº Matrícula (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedTurmaId,
                decoration: const InputDecoration(labelText: 'Turma', border: OutlineInputBorder()),
                items: _turmas.map((t) => DropdownMenuItem<String>(
                  value: t['id'].toString(),
                  child: Text(t['nome']),
                )).toList(),
                onChanged: (val) => setDialogState(() => _selectedTurmaId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: _addAluno, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: _alunos.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_alt_1_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhum aluno cadastrado', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('CADASTRAR PRIMEIRO ALUNO'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _alunos.length,
                  itemBuilder: (context, index) {
                    final aluno = _alunos[index];
                    final turma = _turmas.firstWhere((t) => t['id'] == aluno['turma_id'], orElse: () => {'nome': 'N/A'});
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                        title: Text(aluno['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Turma: ${turma['nome']} | Matrícula: ${aluno['matricula'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _supabase.from('alunos').delete().eq('id', aluno['id']);
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('NOVO ALUNO'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}