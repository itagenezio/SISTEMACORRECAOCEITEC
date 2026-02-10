import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TurmasPage extends StatefulWidget {
  const TurmasPage({super.key});

  @override
  State<TurmasPage> createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  final _supabase = Supabase.instance.client;
  final _nomeController = TextEditingController();
  int? _selectedEscolaId;
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _escolas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final escRes = await _supabase.from('escolas').select().order('nome');
      final turRes = await _supabase.from('turmas').select().order('nome');
      setState(() {
        _escolas = List<Map<String, dynamic>>.from(escRes);
        _turmas = List<Map<String, dynamic>>.from(turRes);
      });
    } catch (e) {
      _showError('Erro ao carregar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTurma() async {
    if (_nomeController.text.isEmpty || _selectedEscolaId == null) {
      _showError('Preencha o nome e selecione uma escola');
      return;
    }
    try {
      await _supabase.from('turmas').insert({
        'nome': _nomeController.text,
        'escola_id': _selectedEscolaId,
      });
      _nomeController.clear();
      if (mounted) Navigator.pop(context);
      _loadData();
    } catch (e) {
      _showError('Erro ao adicionar: $e');
    }
  }

  void _showAddDialog() {
    if (_escolas.isEmpty) {
      _showError('Cadastre uma escola antes de criar turmas!');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Turma'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Turma', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                value: _selectedEscolaId,
                decoration: const InputDecoration(labelText: 'Escola Responsável', border: OutlineInputBorder()),
                items: _escolas.map((e) => DropdownMenuItem<int>(
                  value: e['id'],
                  child: Text(e['nome']),
                )).toList(),
                onChanged: (val) => setDialogState(() => _selectedEscolaId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: _addTurma, child: const Text('Salvar')),
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
            child: _turmas.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhuma turma cadastrada', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('CADASTRAR PRIMEIRA TURMA'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _turmas.length,
                  itemBuilder: (context, index) {
                    final turma = _turmas[index];
                    final escola = _escolas.firstWhere((e) => e['id'] == turma['escola_id'], orElse: () => {'nome': 'N/A'});
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.group, color: Colors.white)),
                        title: Text(turma['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Escola: ${escola['nome']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _supabase.from('turmas').delete().eq('id', turma['id']);
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
        label: const Text('NOVA TURMA'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}