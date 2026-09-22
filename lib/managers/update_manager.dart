import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/models/app_release.dart';
import 'package:momento_booth/models/changelog_section.dart';
import 'package:momento_booth/models/version_history.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/app_version.dart';
import 'package:momento_booth/utils/changelog_parser.dart';
import 'package:momento_booth/utils/environment_info.dart';
import 'package:momento_booth/utils/logger.dart';

part 'update_manager.g.dart';

const String _repositoryOwner = 'momentobooth';
const String _repositoryName = 'momentobooth';

/// The GitHub releases overview of MomentoBooth.
const String releasesPageUrl = 'https://github.com/$_repositoryOwner/$_repositoryName/releases';

const String _releasesApiUrl = 'https://api.github.com/repos/$_repositoryOwner/$_repositoryName/releases?per_page=50';
const String _changelogUrl = 'https://raw.githubusercontent.com/$_repositoryOwner/$_repositoryName/main/CHANGELOG.md';

class UpdateManager = UpdateManagerBase with _$UpdateManager;

/// Keeps a record of which application version was used when, and checks GitHub for
/// newer releases.
///
/// The release list comes from the GitHub releases API, while the release notes come
/// from `CHANGELOG.md` on the default branch: the release bodies of older releases only
/// carry a generic installation note.
abstract class UpdateManagerBase with Store, Logger {

  static const Duration _requestTimeout = Duration(seconds: 5);

  // /////////////// //
  // Version history //
  // /////////////// //

  @readonly
  VersionHistory _versionHistory = const VersionHistory();

  // //////////// //
  // Update check //
  // //////////// //

  /// The newest release found on GitHub, or `null` when no check has succeeded yet.
  @readonly
  AppRelease? _latestRelease;

  /// The changelog sections for every version newer than the running one, newest first.
  @readonly
  List<ChangelogSection> _newerVersionsChangelog = [];

  @readonly
  bool _isChecking = false;

  /// The error of the most recent check, or `null` when it succeeded or never ran.
  @readonly
  String? _lastCheckError;

  @computed
  bool get isUpdateAvailable => _latestRelease != null && _latestRelease!.version > currentVersion;

  /// The version the update check compares against.
  ///
  /// This is the running application version, unless a mock version is configured, which
  /// is only honoured in debug builds so that the update flow can be tried out during
  /// development.
  AppVersion get currentVersion => _mockVersion ?? AppVersion.tryParse(packageInfo.version) ?? const AppVersion([0]);

  AppVersion? get _mockVersion {
    if (!kDebugMode) return null;

    String mockAppVersion = getIt<SettingsManager>().settings.debug.mockAppVersion.trim();
    if (mockAppVersion.isEmpty) return null;

    AppVersion? parsed = AppVersion.tryParse(mockAppVersion);
    if (parsed == null) logWarning("Ignoring unparseable mock app version '$mockAppVersion'");
    return parsed;
  }

  /// Whether the update check should run automatically on startup.
  ///
  /// In debug builds the check is skipped unless a mock version is set, so that the
  /// update page does not show up on every launch during development.
  bool get _isAutomaticCheckEnabled {
    if (!getIt<SettingsManager>().settings.enableUpdateCheck) return false;
    if (kDebugMode && _mockVersion == null) return false;
    return true;
  }

  // ////////////// //
  // Initialization //
  // ////////////// //

  Future<void> initialize() async {
    await _loadVersionHistory();
    await _recordCurrentVersion();

    if (!_isAutomaticCheckEnabled) {
      logDebug("Automatic update check is disabled");
      return;
    }

    await checkForUpdate();
  }

  // /////////////// //
  // Version history //
  // /////////////// //

  Future<void> _loadVersionHistory() async {
    SerialiableRepository<VersionHistory> repository = getIt<SerialiableRepository<VersionHistory>>();

    try {
      if (!await repository.hasExistingData()) return;
      _versionHistory = await repository.get();
    } catch (e, s) {
      logError("Could not read the version history, starting a new one", e, s);
      _versionHistory = const VersionHistory();
    }
  }

  /// Records that the running version is in use, adding it to the history the first time
  /// it is seen and updating its usage information on every later start.
  @action
  Future<void> _recordCurrentVersion() async {
    String version = packageInfo.version;
    int build = int.tryParse(packageInfo.buildNumber) ?? 0;
    DateTime now = DateTime.now();

    List<VersionHistoryEntry> entries = [..._versionHistory.entries];
    int index = entries.indexWhere((e) => e.version == version && e.build == build);

    if (index == -1) {
      logInfo("Version $version (build $build) is taken into use for the first time");
      entries.add(VersionHistoryEntry(version: version, build: build, firstUsed: now, lastUsed: now));
    } else {
      entries[index] = entries[index].copyWith(lastUsed: now, startCount: entries[index].startCount + 1);
    }

    _versionHistory = _versionHistory.copyWith(entries: entries);

    try {
      await getIt<SerialiableRepository<VersionHistory>>().write(_versionHistory);
    } catch (e, s) {
      logError("Could not save the version history", e, s);
    }
  }

  // //////////// //
  // Update check //
  // //////////// //

  /// Checks GitHub for releases newer than [currentVersion] and loads their changelog.
  @action
  Future<void> checkForUpdate() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      List<AppRelease> releases = await _fetchReleases();
      AppRelease? newest = releases.fold<AppRelease?>(null, (a, b) => a == null || b.version > a.version ? b : a);

      if (newest == null) throw const UpdateCheckException("The GitHub releases API returned no usable releases");

      _latestRelease = newest;
      _lastCheckError = null;

      if (newest.version <= currentVersion) {
        logInfo("No update available, ${currentVersion.versionString} is the newest version");
        _newerVersionsChangelog = [];
        return;
      }

      logInfo("Update available: ${newest.tagName} (running ${currentVersion.versionString})");
      _newerVersionsChangelog = await _fetchChangelogSince(currentVersion, upTo: newest.version);
    } catch (e, s) {
      logWarning("Could not check for updates", e, s);
      _lastCheckError = e.toString();
      _latestRelease = null;
      _newerVersionsChangelog = [];
    } finally {
      _isChecking = false;
    }
  }

  Future<List<AppRelease>> _fetchReleases() async {
    http.Response response = await http.get(
      Uri.parse(_releasesApiUrl),
      headers: const {'Accept': 'application/vnd.github+json'},
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw UpdateCheckException("The GitHub releases API returned HTTP ${response.statusCode}");
    }

    List<dynamic> json = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return json.map((e) => AppRelease.fromGitHubJson(e as Map<String, dynamic>)).nonNulls.toList();
  }

  /// Fetches the changelog and returns the sections for every version after [since] and
  /// up to and including [upTo], newest first.
  Future<List<ChangelogSection>> _fetchChangelogSince(AppVersion since, {required AppVersion upTo}) async {
    http.Response response = await http.get(Uri.parse(_changelogUrl)).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw UpdateCheckException("Fetching the changelog returned HTTP ${response.statusCode}");
    }

    List<ChangelogSection> sections = ChangelogParser.parse(utf8.decode(response.bodyBytes));

    return sections.where((section) => section.parsedVersion > since && section.parsedVersion <= upTo).toList()
      ..sort((a, b) => b.parsedVersion.compareTo(a.parsedVersion));
  }

}

/// Thrown when the update check cannot complete.
class UpdateCheckException implements Exception {

  final String message;

  const UpdateCheckException(this.message);

  @override
  String toString() => message;

}
