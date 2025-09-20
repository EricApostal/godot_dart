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
export 'src/core/gdextension_ffi_bindings.dart'
    hide GDExtensionInitializationLevel;
export 'src/extensions/async_extensions.dart';
export 'src/extensions/core_extensions.dart';
export 'src/gen/engine_classes.dart';
export 'src/gen/global_constants.dart';
export 'src/gen/utility_functions.dart';
export 'src/gen/builtins.dart';
export 'src/gen/native_structures.dart';
export 'src/variant/variant.dart' hide getToTypeConstructor;

// Initialize the Dart DL API in the native library as early as possible.
// This calls the C function `init_dart_api_dl(NativeApi.initializeApiDLData)`.
final int _dartDlApiVersion = (() {
  try {
    final lib = DynamicLibrary.process();
    final init = lib.lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>('init_dart_api_dl');
    final ver = init(NativeApi.initializeApiDLData);
    return ver;
  } catch (_) {
    // If the symbol isn't available yet, native side will print a helpful message
    // and Dart can retry later before using any Dart_* APIs.
    return 0;
  }
})();

// ignore: unused_element
late GodotDart _globalExtension;
// ignore: unused_element
bool _isReloading = false;

void registerGodot(int extensionToken, int bindingCallbacks) {
  print('GODOT DART REGISTER GODOT');
  // Ensure the native Dart DL API is initialized (retry if top-level init failed).
  if (_dartDlApiVersion == 0) {
    try {
      final lib = DynamicLibrary.process();
      final init = lib.lookupFunction<IntPtr Function(Pointer<Void>),
          int Function(Pointer<Void>)>('init_dart_api_dl');
      init(NativeApi.initializeApiDLData);
    } catch (_) {
      // Ignore; native side will guard and print a helpful message if still uninitialized.
    }
  }
  final godotDart = DynamicLibrary.process();
  final ffiInterface = GDExtensionFFI(godotDart);

  final extensionPtr = GDExtensionClassLibraryPtr.fromAddress(extensionToken);
  final bindingCallbackPtr =
      Pointer<GDExtensionInstanceBindingCallbacks>.fromAddress(
          bindingCallbacks);
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
