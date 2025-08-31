/// Library for supporting Dart in the Godot Game Engine
library godot_dart;

import 'dart:ffi';

import 'src/core/gdextension.dart';
import 'src/core/gdextension_ffi_bindings.dart';
import 'src/core/type_info.dart';
import 'src/extensions/async_extensions.dart';
import 'src/gen/utility_functions.dart';
import 'src/variant/variant.dart';

export 'src/annotations/godot_script.dart';
export 'src/core/core_types.dart';
export 'src/core/signals.dart' hide SignalCallable;
export 'src/core/gdextension.dart';
export 'src/core/property_info.dart';
export 'src/core/rpc_info.dart';
export 'src/core/type_info.dart';
export 'src/core/type_resolver.dart';
export 'src/extensions/async_extensions.dart';
export 'src/extensions/core_extensions.dart';
export 'src/gen/engine_classes.dart';
export 'src/gen/global_constants.dart';
export 'src/gen/utility_functions.dart';
export 'src/gen/builtins.dart';
export 'src/gen/native_structures.dart';
export 'src/variant/variant.dart' hide getToTypeConstructor;

// ignore: unused_element
late GodotDart _globalExtension;
// ignore: unused_element
bool _isReloading = false;

void registerGodot(int extensionPointer, int bindingCallbacksPointer) {
  final godotDart = DynamicLibrary.process();
  final ffiInterface = GDExtensionFFI(godotDart);

  final extensionPtr = GDExtensionClassLibraryPtr.fromAddress(extensionPointer);
  final bindingCallbackPtr =
      Pointer<GDExtensionInstanceBindingCallbacks>.fromAddress(
          bindingCallbacksPointer);
  // TODO: Assert everything is how we expect.
  _globalExtension = GodotDart(ffiInterface, extensionPtr, bindingCallbackPtr);

  initVariantBindings(ffiInterface);
  TypeInfo.initTypeMappings();

  GD.initBindings();
  SignalAwaiter.bind();
  CallbackAwaiter.bind();

  print('[godot_dart] Everything loaded a-ok!');
}

typedef PrintClosure = void Function(String line);
@pragma('vm:entry-point')
PrintClosure _getPrintClosure() {
  return (s) => _globalExtension.dartBindings.printNative(s);
}
