import 'package:flutter/material.dart';

/// Helper pour afficher un bottom sheet de filtre avec header standard.
///
/// [title] : titre du filtre
/// [showClear] : affiche le bouton "Effacer"
/// [onClear] : callback du bouton "Effacer"
/// [language] : langue pour les labels
/// [initialChildSize] : taille initiale du sheet (défaut 0.55)
/// [useDraggable] : utilise DraggableScrollableSheet (défaut true)
/// [builder] : construit le contenu sous le header. Reçoit le scrollController si draggable.
void showFilterBottomSheet({
  required BuildContext context,
  required String title,
  required String language,
  bool showClear = false,
  VoidCallback? onClear,
  double initialChildSize = 0.55,
  bool useDraggable = true,
  required Widget Function(ScrollController? scrollController) builder,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: useDraggable,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget header = Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (showClear)
                TextButton(
                  onPressed: () {
                    onClear?.call();
                    Navigator.pop(ctx);
                  },
                  child: Text(language == 'fr' ? 'Effacer' : 'Clear'),
                ),
            ],
          );

          if (!useDraggable) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 12),
                  builder(null),
                ],
              ),
            );
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            maxChildSize: 0.85,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    header,
                    const SizedBox(height: 12),
                    Expanded(child: builder(scrollController)),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
