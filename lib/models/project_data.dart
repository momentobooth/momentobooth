import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toml/toml.dart';

part 'project_data.freezed.dart';
part 'project_data.g.dart';

@freezed
abstract class ProjectsList with _$ProjectsList implements TomlEncodableValue  {

  const ProjectsList._();

  const factory ProjectsList({
    @Default([]) List<ProjectData> list,
  }) = _ProjectsList;

  factory ProjectsList.fromJson(Map<String, Object?> json) => _$ProjectsListFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}

@freezed
abstract class ProjectData with _$ProjectData implements TomlEncodableValue  {

  const ProjectData._();

  const factory ProjectData({
    required String path,
    required DateTime opened,
    @Default("") String note,
  }) = _ProjectData;

  factory ProjectData.fromJson(Map<String, Object?> json) => _$ProjectDataFromJson(json);

  @override
  Map<String, dynamic> toTomlValue() => toJson();

}
