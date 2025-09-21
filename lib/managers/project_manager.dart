import 'dart:io';
import 'dart:ui';

import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/settings_manager.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/models/project_data.dart';
import 'package:momento_booth/models/project_settings.dart';
import 'package:momento_booth/models/subsystem.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/repositories/serializable/toml_serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart' hide context;

part 'project_manager.g.dart';

class ProjectManager = ProjectManagerBase with _$ProjectManager;

abstract class ProjectManagerBase extends Subsystem with Store, Logger {

  @override
  String subsystemName = "Project settings";

  @readonly
  bool _isOpen = false;

  @readonly
  Directory? _path;
  List<Directory> projects = [];

  // Loading the settings with default values to prevent errors from use before initialization.
  // This is fine as the initialize method overwrites the value anyway.
  @readonly
  ProjectSettings _settings = ProjectSettings();

  Color get primaryColor => _isOpen ? _settings.primaryColor : defaultThemeColor;

  @readonly
  bool _blockSaving = false;

  static const subDirs = ["Input", "Output", "Templates"];

  @readonly
  late ProjectsList _projectsList;

  SerialiableRepository<ProjectSettings>? getRepo(){
    if (!_isOpen) return null;
    return TomlSerializableRepository(join(_path!.path, "ProjectSettings.toml"), ProjectSettings.fromJson);
  }

  @override
  Future<void> initialize() async {
    SerialiableRepository<ProjectsList> projectsListRepository = getIt<SerialiableRepository<ProjectsList>>();

    try {
      bool hasExistingProjectsList = await projectsListRepository.hasExistingData();

      if (!hasExistingProjectsList) {
        _projectsList = const ProjectsList();
        reportSubsystemOk(message: "No existing ProjectsList data found, a new file will be created.");
      } else {
        _projectsList = await projectsListRepository.get();
        reportSubsystemOk();
      }
    } catch (e) {
      _projectsList = const ProjectsList();
      reportSubsystemWarning(
        message: "Could not read existing ProjectsList: $e\n\nThe ProjectsList have been cleared. As such the existing ProjectsList file will be overwritten.",
      );
    }

    final args = getIt<ArgResults>().option("open");
    if (args != null) {
      await open(args);
    } else if (getIt<SettingsManager>().settings.loadLastProject) {
      await openLastProject();
    }
  }

  @action
  Future<void> updateAndSave(ProjectSettings settings) async {
    if (!_isOpen) return;
    if (settings == _settings) return;

    if (!_blockSaving) {
      logDebug("Saving settings");
      await getRepo()!.write(settings);
      logDebug("Saved settings");
    } else {
      logDebug("Saving blocked");
    }

    _settings = settings;
    // TODO implement MQTT project related property publishing
    // getIt<MqttManager>().publishSettings(settings);
  }

  void _ensureSubDirs() {
    if (_path != null) {
      for (final subDir in subDirs){
        Directory(join(_path!.path, subDir)).createSync();
      }
    }
  }

  Future<void> openLastProject() async {
    return open(_projectsList.list.sorted((a, b) => b.opened.compareTo(a.opened)).first.path);
  }

  Future<void> open(String projectPath) async {
    // First task: find or create project list item
    var directory = Directory(projectPath);
    final absPath = canonicalize(directory.path);
    // Check if there is already an entry for this path in the projects list. This is done by comparing the path.
    final List<ProjectData> currentList = List.from(_projectsList.list);
    final existingProjectEntries = currentList.indexed.where((e) => canonicalize(e.$2.path) == absPath).toList();
    late final ProjectData entry;
    if (existingProjectEntries.isEmpty) {
      // Create directory and add entry to our projects list
      directory.createSync();
      entry = ProjectData(opened: DateTime.now(), path: directory.path);
      currentList.add(entry);
    } else {
      // Update the entry in the projects list.
      final (index, currentEntry) = existingProjectEntries.first;
      entry = currentEntry.copyWith(opened: DateTime.now());
      currentList[index] = entry;
    }
    // Sort list based on last opened
    currentList.sort((a, b) => b.opened.compareTo(a.opened));
    _projectsList = _projectsList.copyWith(list: currentList);

    // Second task: set project as being opened
    _path = directory;
    _isOpen = true;
    getIt<WindowManager>().setTitle(entry.name);
    _ensureSubDirs();
    await _saveProjectsList();

    // Load project settings
    try {
      final repo = getRepo()!;
      bool hasExistingProjectsList = await repo.hasExistingData();

      if (!hasExistingProjectsList) {
        _settings = const ProjectSettings();
        reportSubsystemOk(message: "No existing ProjectsList data found, a new file will be created.");
      } else {
        _settings = await repo.get();
        reportSubsystemOk();
      }
    } catch (e) {
      _projectsList = const ProjectsList();
      reportSubsystemWarning(
        message: "Could not read existing ProjectSettings: $e\n\nThe ProjectSettings have been cleared. As such the existing ProjectSettings file will be overwritten.",
      );
    }
  }

  Future<bool> browseOpen() async {
    // TODO get a translation delegate in here somehow
    final pathToOpen = await getDirectoryPath(confirmButtonText: "Open folder as project");
    if (pathToOpen != null) {
      await open(pathToOpen);
      return true;
    }
    return false;
  }

  List<ProjectData> listProjects() {
    return _projectsList.list;
  }

  Future<List<String>> listProjectsAsStrings() async {
    final parsedList = await getIt<SerialiableRepository<ProjectsList>>().get();
    return parsedList.list.map((el) => el.path).toList();
  }

  Future<void> _saveProjectsList() async {
    await getIt<SerialiableRepository<ProjectsList>>().write(_projectsList);
  }

  Directory getTemplateDir() {
    return Directory(join(_path!.path, subDirs[2]));
  }

  Directory getInputDir() {
    return Directory(join(_path!.path, subDirs[0]));
  }

  Directory getOutputDir() {
    return Directory(join(_path!.path, subDirs[1]));
  }

}
