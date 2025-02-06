import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/app_localizations.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/window_manager.dart';
import 'package:momento_booth/models/project_data.dart';
import 'package:momento_booth/repositories/serializable/serializable_repository.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:momento_booth/utils/subsystem.dart';
import 'package:path/path.dart' hide context;

part 'project_manager.g.dart';

class ProjectManager = ProjectManagerBase with _$ProjectManager;

abstract class ProjectManagerBase with Store, Logger, Subsystem {

  bool isOpen = false;
  Directory? _path;
  List<Directory> projects = [];

  static const subDirs = ["Input", "Output", "Templates"];
  
  @readonly
  late ProjectsList _projectsList;

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
  }

  void ensureSubDirs() {
    if (_path != null) {
      for (final subDir in subDirs){
        Directory(join(_path!.path, subDir)).createSync();
      }
    }
  }

  void open(String projectPath) {
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
      // final currentEntry = currentList.removeAt(index);
      entry = currentEntry.copyWith(opened: DateTime.now());
      currentList[index] = entry;
    }
    // Sort list based on last opened
    currentList.sort((a, b) => b.opened.compareTo(a.opened));
    _projectsList = _projectsList.copyWith(list: currentList);
    _path = directory;
    isOpen = true;
    getIt<WindowManager>().setTitle(entry.name);
    _saveProjectsList();
  }

  Future<bool> browseOpen() async {
    // TODO get a translation delegate in here somehow
    final pathToOpen = await getDirectoryPath(confirmButtonText: "Open folder as project");
    if (pathToOpen != null) {
      open(pathToOpen);
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
