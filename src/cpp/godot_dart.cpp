#include <gdextension_interface.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/editor_plugin_registration.hpp>

#include "gde_wrapper.h"
#include "dart_bindings.h"

namespace godot_dart {


void initialize_level(godot::ModuleInitializationLevel p_level) {
  // TODO - Should we setup different types at different times?
  if (p_level != godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }

  auto gde = GDEWrapper::instance();

  if (!gde->initialize()) {
    return;
  }

}

void deinitialize_level(godot::ModuleInitializationLevel p_level) {
  if (p_level != godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_SCENE) {
    return;
  }
}

} // namespace godot_dart

extern "C" {

  // todo: remove the stupid ai shit where it has two different definitions for embedded / not

// Maintain a single instance of GodotDartBindings for the embedded runtime path
static GodotDartBindings *s_dart_bindings = nullptr;

void GDE_EXPORT initialize_level(godot::ModuleInitializationLevel p_level) {
  godot_dart::initialize_level(p_level);
}

void GDE_EXPORT deinitialize_level(godot::ModuleInitializationLevel p_level) {
  godot_dart::deinitialize_level(p_level);
}

bool GDE_EXPORT godot_dart_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
                                GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
  gde_init_c_interface(p_get_proc_address);
  GDEWrapper::create_instance(p_get_proc_address, p_library);

  godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

  init_obj.register_initializer(initialize_level);
  init_obj.register_terminator(deinitialize_level);
  init_obj.set_minimum_library_initialization_level(
      godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_SCENE);

  return init_obj.init();
}

bool GDE_EXPORT godot_dart_embedded_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
                                         GDExtensionClassLibraryPtr p_library) {
  gde_init_c_interface(p_get_proc_address);
  GDEWrapper::create_instance(p_get_proc_address, p_library);
  
  godot_dart::initialize_level(godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_SCENE);
  if (!s_dart_bindings) {
    s_dart_bindings = new GodotDartBindings();
  }
  if (!s_dart_bindings->initialize()) {
    delete s_dart_bindings;
    s_dart_bindings = nullptr;
    return false;
  }
  
  return true;
}

void GDE_EXPORT godot_dart_embedded_shutdown() {
  if (s_dart_bindings) {
    s_dart_bindings->shutdown();
    delete s_dart_bindings;
    s_dart_bindings = nullptr;
  }
  godot_dart::deinitialize_level(godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_SCENE);
}

bool GDE_EXPORT godot_dart_initialize_runtime() {
  return true;
}

void GDE_EXPORT godot_dart_shutdown_runtime() {
}

}
