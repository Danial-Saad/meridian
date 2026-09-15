import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../store/meridian_store.dart';
import '../../theme/app_theme.dart';
import '../shared/confirm_dialog.dart';
import 'resource_modal.dart';

class ResourceCardWidget extends StatelessWidget {
  final UserResource resource;

  const ResourceCardWidget({super.key, required this.resource});

  Future<void> _open(BuildContext context) async {
    final store = context.read<MeridianStore>();
    final l10n = AppLocalizations.of(context)!;
    final raw = resource.url.trim();
    if (raw.isEmpty) {
      store.notify(ToastKind.error, l10n.resourceNoLinkError);
      return;
    }
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    if (uri == null || !uri.hasAuthority) {
      store.notify(ToastKind.error, l10n.resourceInvalidLinkError);
      return;
    }
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) store.notify(ToastKind.error, l10n.resourceOpenLinkError);
    } catch (_) {
      store.notify(ToastKind.error, l10n.resourceOpenLinkError);
    }
  }

  void _showOptions(BuildContext context, MeridianStore store) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = context.read<ThemeController>().colors;
        return Container(
          decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: c.text),
                title: Text(l10n.editResourceLabel, style: TextStyle(color: c.text)),
                onTap: () {
                  Navigator.pop(ctx);
                  showResourceModal(context,
                      resource: resource,
                      onSave: (updated) =>
                          store.updateResource(resource.id, (_) => updated));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: c.danger),
                title:
                    Text(l10n.deleteResourceLabel, style: TextStyle(color: c.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  showMrdConfirm(
                    context,
                    title: l10n.resourceDeleteTitle,
                    description: l10n.taskDeleteDesc(resource.title),
                    confirmLabel: l10n.deleteLabel,
                    onConfirm: () => store.deleteResource(resource.id),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    // PERF FIX: `store` below is only ever used inside onLongPress/onPressed
    // callbacks, never to render anything. `watch` was subscribing every
    // single resource card (each holding a decoded image) to rebuild on
    // *any* app-wide store change (a task toggle, a habit check-off,
    // anything) even though nothing here depends on that data. `read`
    // gets the same instance for the callbacks without the subscription.
    final store = context.read<MeridianStore>();

    // Photos picked from the gallery can easily be several thousand
    // pixels wide, but this card only ever shows the image at its own
    // (at most phone-width) box. Decoding at full resolution for every
    // card in the grid is the classic Flutter image-memory trap, so cap
    // the decode to roughly what a single card can actually display.
    final thumbDecodeWidth =
        (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio)
            .round()
            .clamp(0, 1000);

    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(16),
          color: c.surface),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          onLongPress: () => _showOptions(context, store),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: resource.imagePath.isEmpty
                        ? _ImageFallback(c: c)
                        : Image.file(
                            File(resource.imagePath),
                            fit: BoxFit.cover,
                            cacheWidth: thumbDecodeWidth,
                            errorBuilder: (context, error, stackTrace) =>
                                _ImageFallback(c: c),
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.more_vert,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => _showOptions(context, store),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text,
                          height: 1.25),
                    ),
                    if (resource.description != null &&
                        resource.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        resource.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: c.textDim, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final MeridianColors c;
  const _ImageFallback({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: c.surfaceHover,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          size: 26, color: c.textFaint),
    );
  }
}
