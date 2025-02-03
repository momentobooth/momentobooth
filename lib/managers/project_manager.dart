import 'dart:io';

import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
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
    // Check if there is already an entry for this path in the projects list
    final existingProjectEntry = _projectsList.list.where((e) => canonicalize(e.path) == absPath).indexed.toList();
    if (existingProjectEntry.isEmpty) {
      // Create directory and add entry to our projects list
      directory.createSync();
      _projectsList.list.add(ProjectData(opened: DateTime.now(), path: directory.path));
    } else {
      // Update the entry in the projects list.
      final (index, entry) = existingProjectEntry.first;
      final newEntry = entry.copyWith(opened: DateTime.now());
      _projectsList.list[index] = newEntry;
    }
    _path = directory;
    isOpen = true;
  }

  Future<List<ProjectData>> listProjects() async {
    return (await getIt<SerialiableRepository<ProjectsList>>().get()).list;
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
