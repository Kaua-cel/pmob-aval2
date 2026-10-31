import 'package:flutter/material.dart';

import '../../models/item_record.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key, this.isProcessing = false, this.onSave});

  final bool isProcessing;
  final Future<void> Function(ItemRecord record)? onSave;

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  ItemStatus _status = ItemStatus.lost;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text('Informe os dados do objeto', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Não informe dados pessoais ou sensíveis.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: !widget.isProcessing,
                maxLength: ItemFieldLimits.nameMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nome do objeto',
                  hintText: 'Ex.: Guarda-chuva preto',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !widget.isProcessing,
                maxLength: ItemFieldLimits.descriptionMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Descrição',
                  hintText: 'Descreva características que ajudem a identificar o objeto',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                enabled: !widget.isProcessing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Local',
                  hintText: 'Ex.: Biblioteca',
                ),
              ),
              const SizedBox(height: 24),
              Text('Situação', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<ItemStatus>(
                segments: const [
                  ButtonSegment<ItemStatus>(
                    value: ItemStatus.lost,
                    icon: Icon(Icons.search_off_outlined),
                    label: Text('Perdido'),
                  ),
                  ButtonSegment<ItemStatus>(
                    value: ItemStatus.found,
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Encontrado'),
                  ),
                ],
                selected: <ItemStatus>{_status},
                onSelectionChanged: widget.isProcessing
                    ? null
                    : (Set<ItemStatus> selected) => setState(() => _status = selected.first),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: widget.isProcessing || widget.onSave == null ? null : _submit,
                icon: widget.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(widget.isProcessing ? 'Salvando...' : 'Salvar objeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Field validation and record creation are added with the form rules.
  }
}
