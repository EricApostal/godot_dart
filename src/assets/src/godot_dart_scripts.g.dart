// GENERATED FILE - DO NOT MODIFY

import 'package:godot_dart/godot_dart.dart';

class TypeResolverImpl implements TypeResolver {
  @override
  String? pathFromType(Type scriptType) {
    final Map<Type, String> typeFileMap = {};
    return typeFileMap[scriptType];
  }

  @override
  Type? typeFromPath(String scriptPath) {
    final Map<String, Type> fileTypeMap = {};
    return fileTypeMap[scriptPath];
  }

  @override
  List<String> getGlobalClassPaths() {
    return [];
  }
}

void attachScriptResolver() {
  final TypeResolverImpl resolver = TypeResolverImpl();
  gde.dartBindings.attachTypeResolver(resolver);
}
