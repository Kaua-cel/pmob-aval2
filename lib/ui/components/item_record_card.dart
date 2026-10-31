import 'package:flutter/material.dart';

import '../../models/item_record.dart';

class CartaoRegistroItem extends StatelessWidget {
  const CartaoRegistroItem({super.key, required this.record});

  final ItemRecord record;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isLost = record.status == ItemStatus.lost;
    final Color statusColor = isLost ? colorScheme.error : colorScheme.tertiary;
    final Color statusContainer = isLost
        ? colorScheme.errorContainer
        : colorScheme.tertiaryContainer;
    final Color onStatusContainer = isLost
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;
    final String statusLabel = isLost ? 'Perdido' : 'Encontrado';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(record.name, style: Theme.of(context).textTheme.titleMedium)),
                const SizedBox(width: 12),
                Semantics(
                  label: 'Situação: $statusLabel',
                  child: Chip(
                    avatar: Icon(
                      isLost ? Icons.search_off_outlined : Icons.check_circle_outline,
                      color: statusColor,
                      size: 18,
                    ),
                    label: Text(statusLabel),
                    backgroundColor: statusContainer,
                    labelStyle: TextStyle(color: onStatusContainer, fontWeight: FontWeight.w600),
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(record.location)),
              ],
            ),
            const SizedBox(height: 12),
            Text(record.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
