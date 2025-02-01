import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/utils/logger.dart';
import 'package:path/path.dart';
import 'package:win32/win32.dart';

part 'project_manager.g.dart';

class ProjectManager = ProjectManagerBase with _$ProjectManager;

abstract class ProjectManagerBase with Store, Logger {

  bool isOpen = false;
  Directory? path;

  static const subDirs = ["Input", "Output", "Templates"];

  void ensureSubDirs() {
    if (path != null) {
      for (final subDir in subDirs){
        Directory(join(path!.path, subDir)).createSync();
      }
    }
  }

  void open(String projectPath) {
    var directory = Directory(projectPath);
    final exists = directory.existsSync();
    if (!exists) {
      // todo throw error
    }
    path = directory;
  }

  Directory getTemplateDir() {
    return Directory(join(path!.path, subDirs[2]));
  }

  Directory getInputDir() {
    return Directory(join(path!.path, subDirs[2]));
  }

  Directory getOutputDir() {
    return Directory(join(path!.path, subDirs[2]));
  }

}
