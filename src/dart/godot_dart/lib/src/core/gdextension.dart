import 'dart:ffi';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import '../gen/builtins.dart';
import '../gen/engine_classes.dart';
import '../variant/variant.dart';
import 'core_types.dart';
import 'gdextension_ffi_bindings.dart';
import 'godot_dart_native_bindings.dart';

GodotDart get gde => GodotDart.instance!;

typedef GodotVirtualFunction = NativeFunction<
    Void Function(GDExtensionClassInstancePtr, Pointer<GDExtensionConstTypePtr>,
        GDExtensionTypePtr)>;

/// Wrapper around the GDExtension interface for easier Dart calls.
class GodotDart {
  static final int destructorSize = sizeOf<GDExtensionPtrDestructor>();

  static GodotDart? instance;

  final GDExtensionFFI ffiBindings;
  final GDExtensionClassLibraryPtr extensionToken;
  final Pointer<GDExtensionInstanceBindingCallbacks> engineBindingCallbacks;

  late GodotDartNativeBindings dartBindings;

  GodotDart(
      this.ffiBindings, this.extensionToken, this.engineBindingCallbacks) {
    instance = this;
    dartBindings = GodotDartNativeBindings();
  }

  // ---------- Builtin value helpers ----------
  void callBuiltinConstructor(
    GDExtensionPtrConstructor constructor,
    GDExtensionTypePtr base,
    List<GDExtensionConstTypePtr> args,
  ) {
    final array = malloc<GDExtensionConstTypePtr>(args.length);
    for (int i = 0; i < args.length; ++i) {
      array[i] = args[i];
    }
    final fn = constructor.asFunction<
        void Function(GDExtensionTypePtr, Pointer<GDExtensionConstTypePtr>)>();
    fn(base, array);
    malloc.free(array);
  }

  void callBuiltinDestructor(
      GDExtensionPtrDestructor destructor, GDExtensionTypePtr base) {
    destructor.asFunction<void Function(GDExtensionTypePtr)>()(base);
  }

  void callBuiltinMethodPtr(
    GDExtensionPtrBuiltInMethod? method,
    GDExtensionTypePtr base,
    GDExtensionTypePtr ret,
    List<GDExtensionConstTypePtr> args,
  ) {
    if (method == null) return;
    final array = malloc<GDExtensionConstTypePtr>(args.length);
    for (int i = 0; i < args.length; ++i) {
      array[i] = args[i];
    }
    final m = method.asFunction<
        void Function(GDExtensionTypePtr, Pointer<GDExtensionConstTypePtr>,
            GDExtensionTypePtr, int)>();
    m(base, array, ret, args.length);
    malloc.free(array);
  }

  // ---------- Object / Variant dynamic calls ----------
  Variant callNativeMethodBind(
    GDExtensionMethodBindPtr function,
    ExtensionType? instance,
    List<Variant> args,
  ) {
    Variant ret = Variant();
    _objectMethodBindCall ??= () {
      final lib = DynamicLibrary.process();
      try {
        return lib
            .lookup<
                    NativeFunction<
                        GDExtensionInterfaceObjectMethodBindCallFunction>>(
                'object_method_bind_call')
            .asFunction<DartGDExtensionInterfaceObjectMethodBindCallFunction>();
      } catch (_) {
        final ptrVar = lib.lookup<
                Pointer<
                    NativeFunction<
                        GDExtensionInterfaceObjectMethodBindCallFunction>>>(
            'gdextension_interface_object_method_bind_call');
        return ptrVar.value
            .asFunction<DartGDExtensionInterfaceObjectMethodBindCallFunction>();
      }
    }();

    using((arena) {
      final errorPtr =
          arena.allocate<GDExtensionCallError>(sizeOf<GDExtensionCallError>());
      final argArray = arena.allocate<GDExtensionConstVariantPtr>(args.length);
      for (int i = 0; i < args.length; ++i) {
        (argArray + i).value = args[i].nativePtr.cast();
      }
      _objectMethodBindCall!(
        function,
        instance?.nativePtr.cast() ?? nullptr.cast(),
        argArray.cast(),
        args.length,
        ret.nativePtr.cast(),
        errorPtr.cast(),
      );
      if (errorPtr.ref.error != GDExtensionCallErrorType.GDEXTENSION_CALL_OK) {
        throw Exception(
            'Error calling function in Godot: Error ${errorPtr.ref.error}, Argument ${errorPtr.ref.argument}, Expected ${errorPtr.ref.expected}');
      }
    });

    return ret;
  }

  Variant variantCall(Variant self, String methodName, List<Variant> args) {
    Variant ret = Variant();
    final gdMethodName = StringName.fromString(methodName);
    using((arena) {
      final errorPtr =
          arena.allocate<GDExtensionCallError>(sizeOf<GDExtensionCallError>());
      final argArray = arena.allocate<GDExtensionConstVariantPtr>(args.length);
      for (int i = 0; i < args.length; ++i) {
        (argArray + i).value = args[i].nativePtr.cast();
      }
      _variantCall ??= () {
        final lib = DynamicLibrary.process();
        try {
          return lib
              .lookup<NativeFunction<GDExtensionInterfaceVariantCallFunction>>(
                  'variant_call')
              .asFunction<DartGDExtensionInterfaceVariantCallFunction>();
        } catch (_) {
          final ptrVar = lib.lookup<
                  Pointer<
                      NativeFunction<GDExtensionInterfaceVariantCallFunction>>>(
              'gdextension_interface_variant_call');
          return ptrVar.value
              .asFunction<DartGDExtensionInterfaceVariantCallFunction>();
        }
      }();
      _variantCall!(
        self.nativePtr.cast(),
        gdMethodName.nativePtr.cast(),
        argArray,
        args.length,
        ret.nativePtr.cast(),
        errorPtr.cast(),
      );
      if (errorPtr.ref.error != GDExtensionCallErrorType.GDEXTENSION_CALL_OK) {
        throw Exception(
            'Error calling function in Godot: Error ${errorPtr.ref.error}, Argument ${errorPtr.ref.argument}, Expected ${errorPtr.ref.expected}');
      }
    });
    return ret;
  }

  Variant variantGetIndexed(Variant self, int index) {
    Variant ret = Variant();
    using((arena) {
      final valid = arena.allocate<Uint8>(sizeOf<Uint8>());
      final oob = arena.allocate<Uint8>(sizeOf<Uint8>());
      _variantGetIndexed ??= () {
        final lib = DynamicLibrary.process();
        try {
          return lib
              .lookup<
                      NativeFunction<
                          GDExtensionInterfaceVariantGetIndexedFunction>>(
                  'variant_get_indexed')
              .asFunction<DartGDExtensionInterfaceVariantGetIndexedFunction>();
        } catch (_) {
          final ptrVar = lib.lookup<
                  Pointer<
                      NativeFunction<
                          GDExtensionInterfaceVariantGetIndexedFunction>>>(
              'gdextension_interface_variant_get_indexed');
          return ptrVar.value
              .asFunction<DartGDExtensionInterfaceVariantGetIndexedFunction>();
        }
      }();
      _variantGetIndexed!(
        self.nativePtr.cast(),
        index,
        ret.nativePtr.cast(),
        valid.cast(),
        oob.cast(),
      );
      if (oob.value != 0) {
        throw RangeError.index(index, self);
      }
    });
    return ret;
  }

  void variantSetIndexed(Variant self, int index, Variant value) {
    using((arena) {
      final valid = arena.allocate<Uint8>(sizeOf<Uint8>());
      final oob = arena.allocate<Uint8>(sizeOf<Uint8>());
      _variantSetIndexed ??= () {
        final lib = DynamicLibrary.process();
        try {
          return lib
              .lookup<
                      NativeFunction<
                          GDExtensionInterfaceVariantSetIndexedFunction>>(
                  'variant_set_indexed')
              .asFunction<DartGDExtensionInterfaceVariantSetIndexedFunction>();
        } catch (_) {
          final ptrVar = lib.lookup<
                  Pointer<
                      NativeFunction<
                          GDExtensionInterfaceVariantSetIndexedFunction>>>(
              'gdextension_interface_variant_set_indexed');
          return ptrVar.value
              .asFunction<DartGDExtensionInterfaceVariantSetIndexedFunction>();
        }
      }();
      _variantSetIndexed!(
        self.nativePtr.cast(),
        index,
        value.nativePtr.cast(),
        valid.cast(),
        oob.cast(),
      );
      if (oob.value != 0) {
        throw RangeError.index(index, self);
      }
    });
  }

  // ---------- Variant pointer accessors (cached) ----------
  GDExtensionPtrBuiltInMethod variantGetBuiltinMethod(
    int variantType, StringName name, int hash) {
  final lib = DynamicLibrary.process();
  try {
    final fn = lib
      .lookup<
        NativeFunction<
          GDExtensionPtrBuiltInMethod Function(UnsignedInt,
            GDExtensionConstStringNamePtr, Int64)>>(
        'variant_get_ptr_builtin_method')
      .asFunction<
        GDExtensionPtrBuiltInMethod Function(int,
          GDExtensionConstStringNamePtr, int)>();
    return fn(variantType, name.nativePtr.cast(), hash);
  } catch (_) {
    final ptrVar = lib.lookup<
      Pointer<
        NativeFunction<
          GDExtensionPtrBuiltInMethod Function(UnsignedInt,
            GDExtensionConstStringNamePtr, Int64)>>>(
      'gdextension_interface_variant_get_ptr_builtin_method');
    final fn = ptrVar.value.asFunction<
      GDExtensionPtrBuiltInMethod Function(
        int, GDExtensionConstStringNamePtr, int)>();
    return fn(variantType, name.nativePtr.cast(), hash);
  }
  }

  GDExtensionPtrConstructor variantGetConstructor(int variantType, int index) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrConstructor Function(
                      UnsignedInt, Int32)>>('variant_get_ptr_constructor')
          .asFunction<GDExtensionPtrConstructor Function(int, int)>();
      return fn(variantType, index);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrConstructor Function(
                          UnsignedInt, Int32)>>>(
          'gdextension_interface_variant_get_ptr_constructor');
      final fn = ptrVar.value.asFunction<
          GDExtensionPtrConstructor Function(int, int)>();
      return fn(variantType, index);
    }
  }

  GDExtensionPtrDestructor variantGetDestructor(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrDestructor Function(UnsignedInt)>>(
              'variant_get_ptr_destructor')
          .asFunction<GDExtensionPtrDestructor Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrDestructor Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_destructor');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrDestructor Function(int)>();
      return fn(variantType);
    }
  }

  GDExtensionPtrGetter variantGetPtrGetter(int variantType, StringName name) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrGetter Function(UnsignedInt,
                      GDExtensionConstStringNamePtr)>>(
              'variant_get_ptr_getter')
          .asFunction<
              GDExtensionPtrGetter Function(
                  int, GDExtensionConstStringNamePtr)>();
      return fn(variantType, name.nativePtr.cast());
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrGetter Function(UnsignedInt,
                          GDExtensionConstStringNamePtr)>>>(
          'gdextension_interface_variant_get_ptr_getter');
      final fn = ptrVar.value.asFunction<
          GDExtensionPtrGetter Function(int, GDExtensionConstStringNamePtr)>();
      return fn(variantType, name.nativePtr.cast());
    }
  }

  GDExtensionPtrSetter variantGetPtrSetter(int variantType, StringName name) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrSetter Function(UnsignedInt,
                      GDExtensionConstStringNamePtr)>>(
              'variant_get_ptr_setter')
          .asFunction<
              GDExtensionPtrSetter Function(
                  int, GDExtensionConstStringNamePtr)>();
      return fn(variantType, name.nativePtr.cast());
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrSetter Function(UnsignedInt,
                          GDExtensionConstStringNamePtr)>>>(
          'gdextension_interface_variant_get_ptr_setter');
      final fn = ptrVar.value.asFunction<
          GDExtensionPtrSetter Function(int, GDExtensionConstStringNamePtr)>();
      return fn(variantType, name.nativePtr.cast());
    }
  }

  GDExtensionPtrIndexedSetter variantGetIndexedSetter(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrIndexedSetter Function(UnsignedInt)>>(
              'variant_get_ptr_indexed_setter')
          .asFunction<GDExtensionPtrIndexedSetter Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrIndexedSetter Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_indexed_setter');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrIndexedSetter Function(int)>();
      return fn(variantType);
    }
  }

  GDExtensionPtrIndexedGetter variantGetIndexedGetter(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrIndexedGetter Function(UnsignedInt)>>(
              'variant_get_ptr_indexed_getter')
          .asFunction<GDExtensionPtrIndexedGetter Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrIndexedGetter Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_indexed_getter');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrIndexedGetter Function(int)>();
      return fn(variantType);
    }
  }

  GDExtensionPtrKeyedSetter variantGetKeyedSetter(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrKeyedSetter Function(UnsignedInt)>>(
              'variant_get_ptr_keyed_setter')
          .asFunction<GDExtensionPtrKeyedSetter Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrKeyedSetter Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_keyed_setter');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrKeyedSetter Function(int)>();
      return fn(variantType);
    }
  }

  GDExtensionPtrKeyedGetter variantGetKeyedGetter(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrKeyedGetter Function(UnsignedInt)>>(
              'variant_get_ptr_keyed_getter')
          .asFunction<GDExtensionPtrKeyedGetter Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrKeyedGetter Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_keyed_getter');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrKeyedGetter Function(int)>();
      return fn(variantType);
    }
  }

  GDExtensionPtrKeyedChecker variantGetKeyedChecker(int variantType) {
    final lib = DynamicLibrary.process();
    try {
      final fn = lib
          .lookup<
              NativeFunction<
                  GDExtensionPtrKeyedChecker Function(UnsignedInt)>>(
              'variant_get_ptr_keyed_checker')
          .asFunction<GDExtensionPtrKeyedChecker Function(int)>();
      return fn(variantType);
    } catch (_) {
      final ptrVar = lib.lookup<
              Pointer<
                  NativeFunction<
                      GDExtensionPtrKeyedChecker Function(UnsignedInt)>>>(
          'gdextension_interface_variant_get_ptr_keyed_checker');
      final fn = ptrVar.value
          .asFunction<GDExtensionPtrKeyedChecker Function(int)>();
      return fn(variantType);
    }
  }

  // ---------- ClassDB / global ----------
  GDExtensionObjectPtr globalGetSingleton(StringName name) {
    _globalGetSingleton ??= () {
      final lib = DynamicLibrary.process();
      try {
        return lib
            .lookup<
                    NativeFunction<
                        GDExtensionInterfaceGlobalGetSingletonFunction>>(
                'global_get_singleton')
            .asFunction<GDExtensionInterfaceGlobalGetSingletonFunction>();
      } catch (_) {
        final ptrVar = lib.lookup<
                Pointer<
                    NativeFunction<
                        GDExtensionInterfaceGlobalGetSingletonFunction>>>(
            'gdextension_interface_global_get_singleton');
        return ptrVar.value
            .asFunction<GDExtensionInterfaceGlobalGetSingletonFunction>();
      }
    }();
    return _globalGetSingleton!(name.nativePtr.cast());
  }

  GDExtensionMethodBindPtr classDbGetMethodBind(
      StringName className, StringName methodName, int hash) {
    _classdbGetMethodBind ??= () {
      final lib = DynamicLibrary.process();
      try {
        return lib
            .lookup<
                    NativeFunction<
                        GDExtensionInterfaceClassdbGetMethodBindFunction>>(
                'classdb_get_method_bind')
            .asFunction<DartGDExtensionInterfaceClassdbGetMethodBindFunction>();
      } catch (_) {
        final ptrVar = lib.lookup<
                Pointer<
                    NativeFunction<
                        GDExtensionInterfaceClassdbGetMethodBindFunction>>>(
            'gdextension_interface_classdb_get_method_bind');
        return ptrVar.value
            .asFunction<DartGDExtensionInterfaceClassdbGetMethodBindFunction>();
      }
    }();
    return _classdbGetMethodBind!(
        className.nativePtr.cast(), methodName.nativePtr.cast(), hash);
  }

  GDExtensionObjectPtr constructObject(StringName className) {
    _classdbConstructObject2 ??= () {
      final lib = DynamicLibrary.process();
      try {
        return lib
            .lookup<
                    NativeFunction<
                        GDExtensionInterfaceClassdbConstructObject2Function>>(
                'classdb_construct_object2')
            .asFunction<GDExtensionInterfaceClassdbConstructObject2Function>();
      } catch (_) {
        final ptrVar = lib.lookup<
                Pointer<
                    NativeFunction<
                        GDExtensionInterfaceClassdbConstructObject2Function>>>(
            'gdextension_interface_classdb_construct_object2');
        return ptrVar.value
            .asFunction<GDExtensionInterfaceClassdbConstructObject2Function>();
      }
    }();
    return _classdbConstructObject2!(className.nativePtr.cast());
  }

  Pointer<Void> getClassTag(StringName className) {
    _classdbGetClassTag ??= () {
      final lib = DynamicLibrary.process();
      try {
        return lib
            .lookup<
                    NativeFunction<
                        GDExtensionInterfaceClassdbGetClassTagFunction>>(
                'classdb_get_class_tag')
            .asFunction<GDExtensionInterfaceClassdbGetClassTagFunction>();
      } catch (_) {
        final ptrVar = lib.lookup<
                Pointer<
                    NativeFunction<
                        GDExtensionInterfaceClassdbGetClassTagFunction>>>(
            'gdextension_interface_classdb_get_class_tag');
        return ptrVar.value
            .asFunction<GDExtensionInterfaceClassdbGetClassTagFunction>();
      }
    }();
    return _classdbGetClassTag!(className.nativePtr.cast());
  }
}

// Cached global function pointers (resolved lazily) ---------------------------------
DartGDExtensionInterfaceObjectMethodBindCallFunction? _objectMethodBindCall;
DartGDExtensionInterfaceVariantCallFunction? _variantCall;
DartGDExtensionInterfaceVariantGetIndexedFunction? _variantGetIndexed;
DartGDExtensionInterfaceVariantSetIndexedFunction? _variantSetIndexed;
GDExtensionInterfaceGlobalGetSingletonFunction? _globalGetSingleton;
DartGDExtensionInterfaceClassdbGetMethodBindFunction? _classdbGetMethodBind;
GDExtensionInterfaceClassdbConstructObject2Function? _classdbConstructObject2;
GDExtensionInterfaceClassdbGetClassTagFunction? _classdbGetClassTag;

extension GodotObjectCast on GodotObject {
  T? as<T>() => this is T ? this as T : null;
}
