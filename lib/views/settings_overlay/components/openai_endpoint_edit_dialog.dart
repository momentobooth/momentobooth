import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/utils/random_string.dart';

/// Called when the user saves an endpoint. [newApiKey] is null when the stored key should be kept as-is.
/// [clearApiKey] is true when the user chose to remove the stored key.
typedef OpenAiEndpointSaveCallback = void Function(OpenAiEndpointSetting endpoint, String? newApiKey, bool clearApiKey);

class OpenAiEndpointEditDialog extends StatefulWidget {

  final OpenAiEndpointSetting? initial;
  final OpenAiEndpointSaveCallback onSave;

  const OpenAiEndpointEditDialog({super.key, this.initial, required this.onSave});

  @override
  State<OpenAiEndpointEditDialog> createState() => _OpenAiEndpointEditDialogState();

}

class _OpenAiEndpointEditDialogState extends State<OpenAiEndpointEditDialog> {

  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  String _apiKey = '';
  bool _clearApiKey = false;

  bool get _isNew => widget.initial == null;
  bool get _canSave => _nameController.text.trim().isNotEmpty && _baseUrlController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _baseUrlController = TextEditingController(text: widget.initial?.baseUrl ?? defaultOpenAiBaseUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Widget _row(String label, Widget field) {
    return Row(
      spacing: 8,
      children: [
        Expanded(child: Text(label, style: FluentTheme.of(context).typography.bodyStrong)),
        Expanded(flex: 2, child: field),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('OpenAI-compatible endpoint'),
      content: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          _row('Name', TextBox(controller: _nameController, placeholder: 'Name', onChanged: (_) => setState(() {}))),
          _row('Base URL', TextBox(controller: _baseUrlController, placeholder: defaultOpenAiBaseUrl, onChanged: (_) => setState(() {}))),
          _row(
            'API key',
            PasswordBox(
              placeholder: _isNew ? 'API key (optional)' : 'Leave empty to keep the current key',
              revealMode: PasswordRevealMode.peekAlways,
              enabled: !_clearApiKey,
              onChanged: (value) => _apiKey = value,
            ),
          ),
          if (!_isNew)
            _row(
              '',
              Checkbox(
                checked: _clearApiKey,
                content: const Text('Remove the stored API key'),
                onChanged: (value) => setState(() => _clearApiKey = value ?? false),
              ),
            ),
        ],
      ),
      actions: [
        Button(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        FilledButton(
          onPressed: _canSave
              ? () {
                  widget.onSave(
                    OpenAiEndpointSetting(
                      id: widget.initial?.id ?? getRandomString(length: 12),
                      name: _nameController.text.trim(),
                      baseUrl: _baseUrlController.text.trim(),
                    ),
                    _clearApiKey || _apiKey.isEmpty ? null : _apiKey,
                    _clearApiKey,
                  );
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

}
