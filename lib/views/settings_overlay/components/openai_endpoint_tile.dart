import 'package:fluent_ui/fluent_ui.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/models/settings.dart';
import 'package:momento_booth/repositories/secrets/secrets_repository.dart';
import 'package:momento_booth/views/settings_overlay/components/openai_endpoint_edit_dialog.dart';

/// Tile for an OpenAI-compatible endpoint, showing whether an API key is stored for it.
class OpenAiEndpointTile extends StatefulWidget {

  final OpenAiEndpointSetting endpoint;
  final Future<void> Function(OpenAiEndpointSetting endpoint, String? newApiKey, bool clearApiKey) onEdit;
  final VoidCallback onDelete;

  const OpenAiEndpointTile({super.key, required this.endpoint, required this.onEdit, required this.onDelete});

  @override
  State<OpenAiEndpointTile> createState() => _OpenAiEndpointTileState();

}

class _OpenAiEndpointTileState extends State<OpenAiEndpointTile> {

  bool? _hasApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKeyStatus();
  }

  @override
  void didUpdateWidget(covariant OpenAiEndpointTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint.id != widget.endpoint.id) _loadApiKeyStatus();
  }

  Future<void> _loadApiKeyStatus() async {
    final apiKey = await getIt<SecretsRepository>().getSecret(openAiEndpointSecretKey(widget.endpoint.id));
    if (mounted) setState(() => _hasApiKey = apiKey != null && apiKey.isNotEmpty);
  }

  String get _apiKeyStatus => switch (_hasApiKey) {
        null => '',
        true => ' · API key stored',
        false => ' · No API key',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        title: Text(widget.endpoint.name),
        subtitle: Text('${widget.endpoint.baseUrl}$_apiKeyStatus'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Tooltip(
              message: 'Edit',
              child: IconButton(
                icon: const Icon(FluentIcons.edit),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) => OpenAiEndpointEditDialog(
                      initial: widget.endpoint,
                      onSave: (updated, newApiKey, clearApiKey) async {
                        Navigator.of(context).pop();
                        await widget.onEdit(updated, newApiKey, clearApiKey);
                        await _loadApiKeyStatus();
                      },
                    ),
                  );
                },
              ),
            ),
            Tooltip(
              message: 'Delete',
              child: IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
