import 'package:fluent_ui/fluent_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/update_manager.dart';
import 'package:momento_booth/models/app_release.dart';
import 'package:momento_booth/models/changelog_section.dart';
import 'package:momento_booth/views/components/content/markdown_view.dart';
import 'package:momento_booth/views/onboarding_screen/components/wizard_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown during onboarding when a newer release is available, listing the changelog of
/// every version between the running one and the newest release.
class UpdateAvailablePage extends StatelessWidget {

  const UpdateAvailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    UpdateManager updateManager = getIt<UpdateManager>();
    AppRelease? release = updateManager.latestRelease;
    List<ChangelogSection> changelog = updateManager.newerVersionsChangelog;

    return WizardPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "A new version is available!",
                style: FluentTheme.of(context).typography.title,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              "You are running ${updateManager.currentVersion.versionString}, while ${release?.version.versionString ?? 'a newer version'} "
              "is the most recent release. Below is what changed since your version.",
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 16.0),
            Expanded(child: _buildChangelog(context, changelog)),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Button(
                onPressed: () => launchUrl(Uri.parse(release?.htmlUrl ?? releasesPageUrl)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8.0,
                  children: [
                    Icon(LucideIcons.download),
                    Text("Open the download page"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangelog(BuildContext context, List<ChangelogSection> changelog) {
    if (changelog.isEmpty) {
      return Text(
        "The changelog for the new version could not be loaded. Open the download page to read it on GitHub.",
        style: FluentTheme.of(context).typography.body,
      );
    }

    return ListView.separated(
      itemCount: changelog.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24.0),
      itemBuilder: (context, index) {
        ChangelogSection section = changelog[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.0,
          children: [
            Text(section.version, style: FluentTheme.of(context).typography.subtitle),
            MarkdownView(blocks: section.blocks),
          ],
        );
      },
    );
  }

}
