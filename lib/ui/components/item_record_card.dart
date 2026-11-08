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

    final Widget statusBadge = Semantics(
      label: 'Situação: $statusLabel',
      child: Chip(
        visualDensity: VisualDensity.compact,
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
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useStackedHeader = constraints.maxWidth < 240;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useStackedHeader) ...[
                  Text(record.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  statusBadge,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(record.name, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(width: 12),
                      statusBadge,
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(child: Text(record.location)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(record.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            );
          },
        ),
      ),
    );
  }
}
