import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../store/meridian_store.dart';
import '../theme/app_theme.dart';
import '../widgets/resources/resource_card_widget.dart';
import '../widgets/resources/resource_modal.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/field_label.dart';
import '../widgets/shared/mrd_bidi_text_field.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final store = context.watch<MeridianStore>();
    final resources = store.resources;
    final l10n = AppLocalizations.of(context)!;

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? resources
        : resources
            .where((r) => r.title.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: resources.isNotEmpty
          ? FloatingActionButton(
              onPressed: () =>
                  showResourceModal(context, onSave: store.addResource),
              backgroundColor: c.primary,
              foregroundColor: c.primaryInk,
              child: const Icon(Icons.add),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(l10n.resourcesTitle,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 4),
          Text(l10n.resourcesSubtitle,
              style: TextStyle(fontSize: 13, color: c.textDim)),
          if (resources.isNotEmpty) ...[
            const SizedBox(height: 12),
            MrdBidiTextField(
              controller: _searchCtrl,
              style: TextStyle(color: c.text, fontSize: 13.5),
              decoration: mrdInputDecoration(c, hint: l10n.searchResourcesHint)
                  .copyWith(
                prefixIcon: Icon(Icons.search, size: 18, color: c.textFaint),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, size: 16, color: c.textFaint),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 18),
          if (resources.isEmpty)
            EmptyState(
              title: l10n.resourcesEmptyTitle,
              subtitle: l10n.resourcesSubtitle,
              actionLabel: l10n.addResourceButton,
              onAction: () =>
                  showResourceModal(context, onSave: store.addResource),
              icon: Icons.school_outlined,
            )
          else if (filtered.isEmpty)
            EmptyState(
              title: l10n.resourcesNoMatchTitle,
              subtitle: l10n.resourcesSubtitle,
              icon: Icons.search_off,
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
              const spacing = 12.0;
              final cardWidth = columns == 1
                  ? width
                  : (width - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final r in filtered)
                    SizedBox(
                        width: cardWidth,
                        child: ResourceCardWidget(resource: r)),
                ],
              );
            }),
        ],
      ),
    );
  }
}
