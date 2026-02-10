import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestoesPage extends StatefulWidget {
  final String? provaId;
  final String? provaTitulo;
  
  const QuestoesPage({super.key, this.provaId, this.provaTitulo});

  @override
  State<QuestoesPage> createState() => _QuestoesPageState();
}

class _QuestoesPageState extends State<QuestoesPage> {
  final _supabase = Supabase.instance.client;
  final _numeroController = TextEditingController();
  final _enunciadoController = TextEditingController();
  String _selectedGabarito = 'A';
  List<Map<String, dynamic>> _questoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuestoes();
  }

  Future<void> _fetchQuestoes() async {
    if (widget.provaId == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('questoes')
          .select()
          .eq('prova_id', widget.provaId as Object)
          .order('numero', ascending: true);
      setState(() {
        _questoes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showError('Erro ao carregar questões: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addQuestao() async {
    if (widget.provaId == null) return;
    try {
      await _supabase.from('questoes').insert({
        'prova_id': widget.provaId,
        'numero': int.tryParse(_numeroController.text) ?? (_questoes.length + 1),
        'enunciado': _enunciadoController.text,
        'gabarito': _selectedGabarito,
      });
      _numeroController.clear();
      _enunciadoController.clear();
      if (mounted) Navigator.pop(context);
      _fetchQuestoes();
    } catch (e) {
      _showError('Erro ao adicionar: $e');
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova Questão'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _numeroController,
                  decoration: InputDecoration(
                    labelText: 'Número da Questão', 
                    hintText: '${_questoes.length + 1}',
                    border: const OutlineInputBorder()
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _enunciadoController,
                  decoration: const InputDecoration(labelText: 'Enunciado (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                const Text('Gabarito Correto:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['A', 'B', 'C', 'D', 'E'].map((letter) {
                    return ChoiceChip(
                      label: Text(letter),
                      selected: _selectedGabarito == letter,
                      onSelected: (selected) {
                        setDialogState(() => _selectedGabarito = letter);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: _addQuestao, child: const Text('Salvar')),
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
      appBar: AppBar(
        title: Text(widget.provaTitulo ?? 'Questões'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchQuestoes,
            child: _questoes.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhuma questão cadastrada para esta prova.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog, 
                        icon: const Icon(Icons.add), 
                        label: const Text('CADASTRAR PRIMEIRA QUESTÃO'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _questoes.length,
                  itemBuilder: (context, index) {
                    final q = _questoes[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(q['numero'].toString())),
                        title: Text(q['enunciado'] != null && q['enunciado'].toString().isNotEmpty ? q['enunciado'] : 'Questão ${q['numero']}'),
                        subtitle: Text('Gabarito: ${q['gabarito']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _supabase.from('questoes').delete().eq('id', q['id']);
                            _fetchQuestoes();
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('NOVA QUESTÃO'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}