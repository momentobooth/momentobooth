import 'package:flutter/widgets.dart';
import 'package:flutter_rust_bridge_example/extensions/build_context_extension.dart';
import 'package:flutter_rust_bridge_example/theme/momento_booth_theme_data.dart';
import 'package:flutter_rust_bridge_example/views/base/build_context_accessor.dart';
import 'package:go_router/go_router.dart';

mixin BuildContextAbstractor {

  BuildContextAccessor get contextAccessor;
  BuildContext get _context => contextAccessor.buildContext;

  MomentoBoothThemeData get theme => _context.theme;
  GoRouter get router => _context.router;

}
