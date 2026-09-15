import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/domain.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../shared/field_label.dart';
import '../shared/mrd_bidi_text_field.dart';

Future<void> showResourceModal(
  BuildContext context, {
  UserResource? resource,
  required void Function(UserResource data) onSave,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ResourceModalSheet(resource: resource, onSave: onSave),
  );
}

class ResourceModalSheet extends StatefulWidget {
  final UserResource? resource;
  final void Function(UserResource data) onSave;

  const ResourceModalSheet({super.key, this.resource, required this.onSave});

  @override
  State<ResourceModalSheet> createState() => _ResourceModalSheetState();
}

class _ResourceModalSheetState extends State<ResourceModalSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _urlCtrl;
  String? _imagePath;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.resource?.title ?? '');
    _descCtrl = TextEditingController(text: widget.resource?.description ?? '');
    _urlCtrl = TextEditingController(text: widget.resource?.url ?? '');
    _imagePath = widget.resource?.imagePath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imagePath = pickedFile.path);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.resourceGiveTitleError);
      return;
    }
    if (_urlCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.resourceProvideUrlError);
      return;
    }
    // Same lenient check resource_card_widget.dart uses when actually
    // opening a resource (auto-prepend https:// if missing, just needs
    // something that resolves to a domain) — moved to save time too, so
    // a typo surfaces immediately instead of the next time the resource
    // is opened, possibly weeks later. Deliberately not tightened beyond
    // what already works when opening, and only checked on submit (like
    // the title field), not on every keystroke.
    final rawUrl = _urlCtrl.text.trim();
    final parsedUrl =
        Uri.tryParse(rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl');
    if (parsedUrl == null || !parsedUrl.hasAuthority) {
      setState(() => _error = l10n.resourceInvalidLinkError);
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });

    String finalImagePath = _imagePath ?? '';

    // Only touches disk when there's actually an image to save — a
    // resource with no image at all (now a valid, common case) just
    // keeps an empty path and _ImageFallback renders in its place.
    if (_imagePath != null &&
        _imagePath!.isNotEmpty &&
        (widget.resource == null || _imagePath != widget.resource?.imagePath)) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${uid()}${p.extension(_imagePath!)}';
        final savedImage =
            await File(_imagePath!).copy('${appDir.path}/$fileName');
        finalImagePath = savedImage.path;

        if (widget.resource?.imagePath != null) {
          final oldFile = File(widget.resource!.imagePath);
          if (oldFile.existsSync()) oldFile.deleteSync();
        }
      } catch (e) {
        setState(() {
          _error = AppLocalizations.of(context)!.resourceSaveImageError;
          _isSaving = false;
        });
        return;
      }
    } else if ((_imagePath == null || _imagePath!.isEmpty) &&
        (widget.resource?.imagePath.isNotEmpty ?? false)) {
      // Image was cleared via the remove (x) button above — the
      // previously-saved file is no longer referenced by anything, so
      // clean it up now instead of leaving it orphaned on disk forever.
      try {
        final oldFile = File(widget.resource!.imagePath);
        if (oldFile.existsSync()) oldFile.deleteSync();
      } catch (_) {
        // Non-fatal: worst case a stale file lingers, which is exactly
        // the pre-existing behavior for every other codepath here too.
      }
    }

    widget.onSave(UserResource(
      id: widget.resource?.id ?? uid(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imagePath: finalImagePath,
      url: _urlCtrl.text.trim(),
      createdAt:
          widget.resource?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    ));

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>().colors;
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.resource != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border),
        ),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? l10n.editResourceModalTitle : l10n.addResourceButton,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: c.text)),
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: c.textDim)),
                ],
              ),
              const SizedBox(height: 8),
              FieldLabel(l10n.coverImageLabel, c: c),
              Stack(children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                      image: _imagePath != null && _imagePath!.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: _imagePath == null || _imagePath!.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 32, color: c.textFaint),
                              const SizedBox(height: 8),
                              Text(l10n.tapToSelectImage,
                                  style: TextStyle(
                                      color: c.textDim, fontSize: 13)),
                            ],
                          )
                        : null,
                  ),
                ),
                // Images are optional now (see the mandatory-image fix in
                // this session) — this is the way back to "no image" for
                // someone who picked one and changed their mind, without
                // needing to reopen the gallery and cancel out of it.
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 14),
              FieldLabel(l10n.titleLabel, c: c),
              MrdBidiTextField(
                controller: _titleCtrl,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration:
                    mrdInputDecoration(c, hint: l10n.resourceTitleHint),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              FieldLabel(l10n.urlLabel, c: c),
              // URLs must stay LTR regardless of surrounding content —
              // deliberately a plain TextField with an explicit direction
              // here, not MrdBidiTextField.
              TextField(
                controller: _urlCtrl,
                textDirection: TextDirection.ltr,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: mrdInputDecoration(c,
                    hint: l10n.resourceUrlHint),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              FieldLabel(l10n.descriptionOptionalLabel, c: c),
              MrdBidiTextField(
                controller: _descCtrl,
                maxLines: 2,
                style: TextStyle(color: c.text, fontSize: 14),
                decoration: mrdInputDecoration(c,
                    hint: l10n.resourceDescHint),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.error_outline, size: 13, color: c.danger),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(color: c.danger, fontSize: 12))),
                ]),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: c.textDim,
                        side: BorderSide(color: c.border)),
                    child: Text(l10n.cancelLabel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.primaryInk),
                    child: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.primaryInk))
                        : Text(isEdit ? l10n.saveChangesButton : l10n.addResourceButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
