import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/models/open_source_package.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lists the licenses of all third-party software MomentoBooth uses, grouped by how it is used.
/// The license information is loaded when this widget is first built.
class OpenSourceLicensesExpander extends StatefulWidget {

  const OpenSourceLicensesExpander({super.key});

  @override
  State<OpenSourceLicensesExpander> createState() => _OpenSourceLicensesExpanderState();

}

class _OpenSourceLicensesExpanderState extends State<OpenSourceLicensesExpander> {

  late final Future<List<OpenSourcePackage>> _packages = OpenSourcePackage.loadAll();

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: const Text('Open source licenses'),
      contentBackgroundColor: Colors.white,
      content: FutureBuilder(
        future: _packages,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasError: true) => Text('Could not load the license information: ${snapshot.error}'),
          AsyncSnapshot(data: null) => const Center(child: ProgressRing()),
          AsyncSnapshot(:final data?) when data.isEmpty => const Text('License information is not included in this build.'),
          AsyncSnapshot(:final data?) => _groups(data),
        },
      ),
    );
  }

  Widget _groups(List<OpenSourcePackage> packages) {
    Iterable<OpenSourcePackage> where(OpenSourceEcosystem ecosystem, OpenSourceUsage usage, {bool? isDirect}) {
      return packages.where((p) => p.ecosystem == ecosystem && p.usage == usage && (isDirect == null || p.isDirect == isDirect));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        const Text('MomentoBooth is built on the work of many open source projects. Thank you to everyone who contributed to them!'),
        const SizedBox(height: 4),
        for (final isDirect in [true, false])
          _PackageGroup(
            title: isDirect ? 'Direct dependencies' : 'Indirect dependencies',
            subgroups: {
              'Dart': where(OpenSourceEcosystem.dart, OpenSourceUsage.runtime, isDirect: isDirect).toList(),
              'Rust': where(OpenSourceEcosystem.rust, OpenSourceUsage.runtime, isDirect: isDirect).toList(),
            },
          ),
        _PackageGroup(
          title: 'Native libraries',
          subgroups: {'': where(OpenSourceEcosystem.native, OpenSourceUsage.runtime).toList()},
        ),
        _PackageGroup(
          title: 'Flutter engine',
          subgroups: {'': where(OpenSourceEcosystem.flutterEngine, OpenSourceUsage.runtime).toList()},
        ),
        _PackageGroup(
          title: 'Build tools & toolchain',
          subgroups: {
            'Toolchain': where(OpenSourceEcosystem.toolchain, OpenSourceUsage.buildTime).toList(),
            'Dart (direct)': where(OpenSourceEcosystem.dart, OpenSourceUsage.buildTime, isDirect: true).toList(),
            'Dart (indirect)': where(OpenSourceEcosystem.dart, OpenSourceUsage.buildTime, isDirect: false).toList(),
          },
        ),
      ],
    );
  }

}

/// An expander listing packages, optionally split into named subgroups. A subgroup with an empty name is listed directly.
/// The rows are only built once the expander is opened, as some groups contain hundreds of packages.
class _PackageGroup extends StatefulWidget {

  final String title;
  final Map<String, List<OpenSourcePackage>> subgroups;

  const _PackageGroup({required this.title, required this.subgroups});

  @override
  State<_PackageGroup> createState() => _PackageGroupState();

}

class _PackageGroupState extends State<_PackageGroup> {

  bool _hasBeenExpanded = false;

  @override
  Widget build(BuildContext context) {
    final subgroups = {
      for (final MapEntry(:key, :value) in widget.subgroups.entries)
        if (value.isNotEmpty) key: value,
    };
    if (subgroups.isEmpty) return const SizedBox();

    final count = subgroups.values.fold(0, (sum, packages) => sum + packages.length);

    return Expander(
      header: Text('${widget.title} ($count)'),
      onStateChanged: (expanded) {
        if (expanded && !_hasBeenExpanded) setState(() => _hasBeenExpanded = true);
      },
      content: !_hasBeenExpanded
          ? const SizedBox()
          : subgroups.length == 1 && subgroups.keys.single.isEmpty
              ? _PackageList(packages: subgroups.values.single)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    for (final MapEntry(:key, :value) in subgroups.entries)
                      _PackageGroup(title: key, subgroups: {'': value}),
                  ],
                ),
    );
  }

}

class _PackageList extends StatelessWidget {

  final List<OpenSourcePackage> packages;

  const _PackageList({required this.packages});

  @override
  Widget build(BuildContext context) {
    final resources = FluentTheme.of(context).resources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PackageRow(
          cells: const ['Name', 'Version', 'License'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(height: 1, color: resources.dividerStrokeColorDefault),
        for (final package in packages)
          HoverButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _LicenseDialog(package: package),
            ),
            builder: (context, states) => ColoredBox(
              color: states.contains(WidgetState.pressed)
                  ? resources.subtleFillColorTertiary
                  : states.contains(WidgetState.hovered)
                      ? resources.subtleFillColorSecondary
                      : resources.subtleFillColorTransparent,
              child: _PackageRow(
                cells: [package.name, package.version ?? '', package.license ?? 'Unknown'],
                trailing: switch (package.url) {
                  final url? => Tooltip(
                      message: url,
                      child: IconButton(
                        icon: const Icon(LucideIcons.externalLink, size: 14),
                        onPressed: () => launchUrl(Uri.parse(url)),
                      ),
                    ),
                  null => null,
                },
              ),
            ),
          ),
      ],
    );
  }

}

/// A single table row with the name, version and license columns, followed by an optional [trailing] action.
class _PackageRow extends StatelessWidget {

  final List<String> cells;
  final TextStyle? style;
  final Widget? trailing;

  const _PackageRow({required this.cells, this.style, this.trailing});

  static const _columnFlex = [3, 1, 2];
  // Fixed so that rows with and without a trailing action have the same height.
  static const _trailingSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        spacing: 16,
        children: [
          for (final (index, cell) in cells.indexed)
            Expanded(
              flex: _columnFlex[index],
              child: Text(cell, style: style, overflow: TextOverflow.ellipsis),
            ),
          SizedBox(width: _trailingSize, height: _trailingSize, child: trailing),
        ],
      ),
    );
  }

}

class _LicenseDialog extends StatelessWidget {

  final OpenSourcePackage package;

  const _LicenseDialog({required this.package});

  @override
  Widget build(BuildContext context) {
    final url = package.url;
    final licenseText = package.licenseText;

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
      title: Text([package.name, ?package.version].join(' ')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (package.description != null) Text(package.description!),
          Text('License: ${package.license ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (url != null)
            HyperlinkButton(
              style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
              onPressed: () => launchUrl(Uri.parse(url)),
              child: Text(url),
            ),
          Flexible(
            child: licenseText != null
                ? SingleChildScrollView(
                    child: SelectableText(licenseText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  )
                : Text(
                    package.ecosystem == OpenSourceEcosystem.toolchain
                        ? 'This tool is not distributed with MomentoBooth. See the project website for its license.'
                        : 'No license text provided.',
                  ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

}
