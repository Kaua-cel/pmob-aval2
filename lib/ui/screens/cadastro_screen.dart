import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/item_record.dart';
import '../../state/item_form_controller.dart';

class TelaCadastroComEstado extends StatefulWidget {
  const TelaCadastroComEstado({super.key, required this.controller, this.onSuccess});

  final ItemFormController controller;
  final FutureOr<void> Function()? onSuccess;

  @override
  State<TelaCadastroComEstado> createState() => _TelaCadastroComEstadoState();
}

class _TelaCadastroComEstadoState extends State<TelaCadastroComEstado> {
  @override
  void dispose() {
    widget.controller.reset();
    super.dispose();
  }

  Future<void> _handleSave(ItemRecord record) async {
    await widget.controller.submit(record);
    await _handleSubmissionResult();
  }

  Future<void> _handleRetry() async {
    await widget.controller.retry();
    await _handleSubmissionResult();
  }

  Future<void> _handleSubmissionResult() async {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    messenger.hideCurrentSnackBar();

    if (widget.controller.state == ItemFormState.success) {
      widget.controller.acknowledgeSuccess();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Objeto cadastrado com sucesso!'),
          duration: Duration(seconds: 3),
        ),
      );
      await widget.onSuccess?.call();
      if (mounted && navigator.canPop()) {
        navigator.pop();
      }
    } else if (widget.controller.state == ItemFormState.failure) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ??
                'Não foi possível cadastrar o objeto. Tente novamente.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return TelaCadastro(
          isProcessing: widget.controller.state == ItemFormState.submitting,
          hasError: widget.controller.state == ItemFormState.failure,
          onSave: _handleSave,
          onRetry: widget.controller.canRetry ? _handleRetry : null,
        );
      },
    );
  }
}

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({
    super.key,
    this.isProcessing = false,
    this.hasError = false,
    this.onSave,
    this.onRetry,
  });

  final bool isProcessing;
  final bool hasError;
  final Future<void> Function(ItemRecord record)? onSave;
  final Future<void> Function()? onRetry;

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isProcessing,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastrar item')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                Text(
                  'Informe os dados do objeto',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
                    requiredMessage: 'O nome do objeto é obrigatório.',
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
                    requiredMessage: 'A descrição é obrigatória.',
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
                if (widget.hasError) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Verifique sua conexão e tente enviar os dados novamente.',
                                  style: TextStyle(color: colorScheme.onErrorContainer),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _retryOrSubmit,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }

  Future<void> _retryOrSubmit() async {
    if (_isProcessing) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (widget.onRetry != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onRetry!();
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_isProcessing || !(_formKey.currentState?.validate() ?? false) || widget.onSave == null) {
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
    required String requiredMessage,
    required String fieldLabel,
    required int maximum,
  }) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }
    if (value.length > maximum) {
      return '$fieldLabel deve ter no máximo $maximum caracteres.';
    }
    return null;
  }
}
