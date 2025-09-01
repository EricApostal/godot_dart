import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../gen/builtins.dart';
import '../gen/engine_classes.dart';
import '../core/gdextension.dart';
import '../core/gdextension_ffi_bindings.dart';
import '../gen/utility_functions.dart';
import '../variant/variant.dart';

extension TNode on Node {
  T? getNodeT<T>([String? path]) {
    var typeInfo = gde.dartBindings.getGodotTypeInfo(T);
    final GDString name;
    if (path != null) {
      name = GDString.fromString(path);
    } else if (typeInfo != null) {
      name = GDString.fromStringName(typeInfo!.className);
    } else {
      print('Null type but probably shouldn\'t be!');
      return null;
    }
    var node = getNode(NodePath.fromGDString(name));
    return node?.as<T>();
  }
}

extension StringExtensions on String {
  static String fromGodotStringPtr(GDExtensionTypePtr ptr) {
    return using((arena) {
      int length =
          gde.ffiBindings.gde_string_to_utf16_chars(ptr.cast(), nullptr, 0);
      final chars = arena.allocate<Uint16>(sizeOf<Uint16>() * length);
      gde.ffiBindings
          .gde_string_to_utf16_chars(ptr.cast(), chars.cast(), length);
      return chars.cast<Utf16>().toDartString(length: length);
    });
  }
}

extension WeakRefExtension on Object {
  WeakRef? getWeak() {
    return GD.weakref(Variant(this)).cast<WeakRef>();
  }
}
