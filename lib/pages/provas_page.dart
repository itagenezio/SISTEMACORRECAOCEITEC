import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'questoes_page.dart';

class ProvasPage extends StatefulWidget {
  const ProvasPage({super.key});

  @override
  State<ProvasPage> createState() => _ProvasPageState();
}

class _ProvasPageState extends State<ProvasPage> {
  final _supabase = Supabase.instance.client;
  final _tituloController = TextEditingController();
  String? _selectedTurmaId;
  List<Map<String, dynamic>> _provas = [];
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
      final proRes = await _supabase.from('provas').select().order('created_at', ascending: false);
      setState(() {
        _turmas = List<Map<String, dynamic>>.from(turRes);
        _provas = List<Map<String, dynamic>>.from(proRes);
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('Could not find the table')) {
        _showError('ERRO: Tabela necessária não encontrada. Execute o script SETUP_DB.sql no Supabase.');
      } else {
        _showError('Erro no banco: ${e.message}');
      }
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProva() async {
    if (_tituloController.text.isEmpty || _selectedTurmaId == null) {
       _showError('Preencha o título e selecione uma turma');
       return;
    }
    try {
      await _supabase.from('provas').insert({
        'titulo': _tituloController.text,
        'turma_id': _selectedTurmaId,
      });
      _tituloController.clear();
      if (mounted) Navigator.pop(context);
      _loadData();
    } catch (e) {
      _showError('Erro ao adicionar: $e');
    }
  }

  void _showAddDialog() {
    if (_turmas.isEmpty) {
      _showError('Cadastre uma turma antes de criar provas!');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Prova'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título da Prova', border: OutlineInputBorder()),
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
            ElevatedButton(onPressed: _addProva, child: const Text('Salvar')),
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
            child: _provas.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhuma prova cadastrada', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('CADASTRAR PRIMEIRA PROVA'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _provas.length,
                  itemBuilder: (context, index) {
                    final prova = _provas[index];
                    final turma = _turmas.firstWhere((t) => t['id'].toString() == prova['turma_id'].toString(), orElse: () => {'nome': 'N/A'});
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.assignment, color: Colors.white)),
                        title: Text(prova['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Turma: ${turma['nome']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list_alt, color: Colors.green),
                              tooltip: 'Gerenciar Questões',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestoesPage(provaId: prova['id'].toString(), provaTitulo: prova['titulo']),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _supabase.from('provas').delete().eq('id', prova['id']);
                                _loadData();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('NOVA PROVA'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
    );
  }
}