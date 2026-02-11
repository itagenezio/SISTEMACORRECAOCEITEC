import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EscolasPage extends StatefulWidget {
  const EscolasPage({super.key});

  @override
  State<EscolasPage> createState() => _EscolasPageState();
}

class _EscolasPageState extends State<EscolasPage> {
  final _supabase = Supabase.instance.client;
  final _nomeController = TextEditingController();
  List<Map<String, dynamic>> _escolas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEscolas();
  }

  Future<void> _fetchEscolas() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('escolas').select().order('nome');
      setState(() {
        _escolas = List<Map<String, dynamic>>.from(response);
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.message.contains('Could not find the table')) {
        _showError('ERRO: Tabela "escolas" não encontrada. Execute o script SETUP_DB.sql no Supabase.');
      } else {
        _showError('Erro ao carregar escolas: ${e.message}');
      }
    } catch (e) {
      _showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEscola() async {
    if (_nomeController.text.isEmpty) return;
    try {
      await _supabase.from('escolas').insert({'nome': _nomeController.text});
      _nomeController.clear();
      if (mounted) Navigator.pop(context);
      _fetchEscolas();
    } catch (e) {
      _showError('Erro ao adicionar: $e');
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Escola'),
        content: TextField(
          controller: _nomeController,
          decoration: const InputDecoration(labelText: 'Nome da Escola', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _addEscola, child: const Text('Salvar')),
        ],
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
            onRefresh: _fetchEscolas,
            child: _escolas.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhuma escola cadastrada', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('CADASTRAR PRIMEIRA ESCOLA'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _escolas.length,
                  itemBuilder: (context, index) {
                    final escola = _escolas[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.school)),
                        title: Text(escola['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _supabase.from('escolas').delete().eq('id', escola['id']);
                            _fetchEscolas();
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('NOVA ESCOLA'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}