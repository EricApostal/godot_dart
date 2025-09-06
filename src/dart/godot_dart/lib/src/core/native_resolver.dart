import 'dart:ffi';

import 'gdextension_ffi_bindings.dart';

DartGDExtensionInterfaceObjectMethodBindPtrcallFunction
    getObjectMethodBindPtrcall() {
  final lib = DynamicLibrary.process();
  return lib
      .lookup<
              NativeFunction<
                  GDExtensionInterfaceObjectMethodBindPtrcallFunction>>(
          'object_method_bind_ptrcall')
      .asFunction<DartGDExtensionInterfaceObjectMethodBindPtrcallFunction>();
}

GDExtensionInterfaceRefGetObjectFunction getRefGetObject() {
  final lib = DynamicLibrary.process();

  return lib
      .lookup<NativeFunction<GDExtensionInterfaceRefGetObjectFunction>>(
          'ref_get_object')
      .asFunction<GDExtensionInterfaceRefGetObjectFunction>();
}

DartGDExtensionInterfaceStringNewWithUtf8CharsFunction
    getStringWithNewUtf8Chars() {
  final lib = DynamicLibrary.process();

  return lib
      .lookup<
              NativeFunction<
                  GDExtensionInterfaceStringNewWithUtf8CharsFunction>>(
          'string_new_with_utf8_chars')
      .asFunction<DartGDExtensionInterfaceStringNewWithUtf8CharsFunction>();
}

// variant_get_ptr_utility_function
DartGDExtensionInterfaceVariantGetPtrUtilityFunctionFunction
    variantGetPtrUtilityFunction() {
  final lib = DynamicLibrary.process();

  return lib
      .lookup<
              NativeFunction<
                  GDExtensionInterfaceVariantGetPtrUtilityFunctionFunction>>(
          'variant_get_ptr_utility_function')
      .asFunction<
          DartGDExtensionInterfaceVariantGetPtrUtilityFunctionFunction>();
}
