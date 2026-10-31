import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isSubmitting = false;

  bool get _isProcessing => widget.isProcessing || _isSubmitting;

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
                enabled: !_isProcessing,
                maxLength: ItemFieldLimits.nameMaxLength,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nome do objeto',
                  hintText: 'Ex.: Guarda-chuva preto',
                ),
                validator: (String? value) => _validateRequiredMaxLength(
                  value,
                  fieldLabel: 'O nome do objeto',
                  maximum: ItemFieldLimits.nameMaxLength,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isProcessing,
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
                validator: (String? value) => _validateRequiredMaxLength(
                  value,
                  fieldLabel: 'A descrição',
                  maximum: ItemFieldLimits.descriptionMaxLength,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                enabled: !_isProcessing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Local',
                  hintText: 'Ex.: Biblioteca',
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o local do objeto.';
                  }
                  return null;
                },
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
                onSelectionChanged: _isProcessing
                    ? null
                    : (Set<ItemStatus> selected) => setState(() => _status = selected.first),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isProcessing || widget.onSave == null ? null : _submit,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isProcessing ? 'Salvando...' : 'Salvar objeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || widget.onSave == null) {
      return;
    }

    final ItemRecord record = ItemRecord(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      status: _status,
    );

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave!(record);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateRequiredMaxLength(
    String? value, {
    required String fieldLabel,
    required int maximum,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldLabel é obrigatório.';
    }
    if (value.length > maximum) {
      return '$fieldLabel deve ter no máximo $maximum caracteres.';
    }
    return null;
  }
}
