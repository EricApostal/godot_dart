#include "ref_counted_wrapper.h"

#include "gde_c_interface.h"
#include "godot_string_wrappers.h"
#include <cstdio>

GDExtensionMethodBindPtr RefCountedWrapper::init_ref_ptr_call = nullptr;
GDExtensionMethodBindPtr RefCountedWrapper::reference_ptr_call = nullptr;
GDExtensionMethodBindPtr RefCountedWrapper::unreference_ptr_call = nullptr;
GDExtensionMethodBindPtr RefCountedWrapper::get_reference_count_ptr_call = nullptr;

bool RefCountedWrapper::init_ref() {
  bool ret = false;
  gde_object_method_bind_ptrcall(init_ref_ptr_call, _object, nullptr, &ret);

  return ret;
}

bool RefCountedWrapper::reference() {
  bool ret = false;
  gde_object_method_bind_ptrcall(reference_ptr_call, _object, nullptr, &ret);

  return ret;
}

bool RefCountedWrapper::unreference() {
  bool ret = false;
  gde_object_method_bind_ptrcall(unreference_ptr_call, _object, nullptr, &ret);

  return ret;
}

int RefCountedWrapper::get_reference_count() {
  int64_t ret = 0;
  gde_object_method_bind_ptrcall(get_reference_count_ptr_call, _object, nullptr, &ret);

  return ret;
}

void RefCountedWrapper::init() {
  printf("Doing Ref counted wrapper ree\n");
  
  const GDExtensionInt class_hash = 2240911060;
  printf("hash shit\n");
  // Construct StringNames using the C GDExtension API to avoid depending on godot-cpp initialization.
  alignas(8) unsigned char class_name_storage[sizeof(void*) * 4] = {};
  GDExtensionUninitializedStringNamePtr class_name = reinterpret_cast<GDExtensionUninitializedStringNamePtr>(class_name_storage);
  gde_string_name_new_with_utf8_chars(class_name, "RefCounted");
  printf("class name and shit\n");
  
  // Method names
  alignas(8) unsigned char init_ref_storage[sizeof(void*) * 4] = {};
  GDExtensionUninitializedStringNamePtr init_ref_sn = reinterpret_cast<GDExtensionUninitializedStringNamePtr>(init_ref_storage);
  gde_string_name_new_with_utf8_chars(init_ref_sn, "init_ref");

  alignas(8) unsigned char reference_storage[sizeof(void*) * 4] = {};
  GDExtensionUninitializedStringNamePtr reference_sn = reinterpret_cast<GDExtensionUninitializedStringNamePtr>(reference_storage);
  gde_string_name_new_with_utf8_chars(reference_sn, "reference");

  alignas(8) unsigned char unreference_storage[sizeof(void*) * 4] = {};
  GDExtensionUninitializedStringNamePtr unreference_sn = reinterpret_cast<GDExtensionUninitializedStringNamePtr>(unreference_storage);
  gde_string_name_new_with_utf8_chars(unreference_sn, "unreference");

  alignas(8) unsigned char get_ref_count_storage[sizeof(void*) * 4] = {};
  GDExtensionUninitializedStringNamePtr get_ref_count_sn = reinterpret_cast<GDExtensionUninitializedStringNamePtr>(get_ref_count_storage);
  gde_string_name_new_with_utf8_chars(get_ref_count_sn, "get_reference_count");

  init_ref_ptr_call = gde_classdb_get_method_bind(class_name, init_ref_sn, class_hash);
  printf("mid wrapper shit\n");
  reference_ptr_call = gde_classdb_get_method_bind(class_name, reference_sn, class_hash);
  unreference_ptr_call = gde_classdb_get_method_bind(class_name, unreference_sn, class_hash);
  get_reference_count_ptr_call = gde_classdb_get_method_bind(class_name, get_ref_count_sn, 3905245786);

  printf("end wrapper shit\n");
}
