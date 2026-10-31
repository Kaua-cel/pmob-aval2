import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/item_record.dart';
import '../../state/item_list_controller.dart';
import '../components/empty_state.dart';
import '../components/item_record_card.dart';
import '../components/list_feedback_state.dart';
import '../routes.dart';

enum EstadoListaObjetos { carregando, sucesso, falha }

class TelaListagemComEstado extends StatefulWidget {
  const TelaListagemComEstado({super.key, required this.controller});

  final ItemListController controller;

  @override
  State<TelaListagemComEstado> createState() => _TelaListagemComEstadoState();
}

class _TelaListagemComEstadoState extends State<TelaListagemComEstado> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) {
        return TelaListagem(
          records: widget.controller.records,
          state: switch (widget.controller.state) {
            ItemListState.loading => EstadoListaObjetos.carregando,
            ItemListState.success => EstadoListaObjetos.sucesso,
            ItemListState.failure => EstadoListaObjetos.falha,
          },
          errorMessage: widget.controller.state == ItemListState.failure
              ? 'Não foi possível acessar os registros. Tente novamente.'
              : null,
          onRefresh: widget.controller.load,
        );
      },
    );
  }
}

class TelaListagem extends StatelessWidget {
  const TelaListagem({
    super.key,
    this.records = const [],
    this.state = EstadoListaObjetos.sucesso,
    this.onRefresh,
    this.onOpenRegistration,
    this.errorMessage,
  });

  final List<ItemRecord> records;
  final EstadoListaObjetos state;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenRegistration;
  final String? errorMessage;

  Future<void> _refresh() async {
    await onRefresh?.call();
  }

  void _openRegistration(BuildContext context) {
    if (onOpenRegistration != null) {
      onOpenRegistration!();
      return;
    }

    Navigator.of(context).pushNamed(RotasAplicativo.cadastro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achados e Perdidos'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Atualizar listagem',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRegistration(context),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar item'),
      ),
    );
  }

  Widget _buildBody() {
    return switch (state) {
      EstadoListaObjetos.carregando => const EstadoCarregandoLista(),
      EstadoListaObjetos.falha => EstadoFalhaLista(onRetry: onRefresh, message: errorMessage),
      EstadoListaObjetos.sucesso when records.isEmpty => const EstadoVazio(),
      EstadoListaObjetos.sucesso => RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: records.length,
          itemBuilder: (BuildContext context, int index) =>
              CartaoRegistroItem(record: records[index]),
          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        ),
      ),
    };
  }
}
