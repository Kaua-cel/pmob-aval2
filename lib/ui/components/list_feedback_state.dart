import 'package:flutter/material.dart';

class EstadoCarregandoLista extends StatelessWidget {
  const EstadoCarregandoLista({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Carregando objetos',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando objetos...'),
          ],
        ),
      ),
    );
  }
}

class EstadoFalhaLista extends StatelessWidget {
  const EstadoFalhaLista({super.key, required this.onRetry, this.message});

  final Future<void> Function()? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Não foi possível carregar os objetos.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry == null ? null : () => onRetry!(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
