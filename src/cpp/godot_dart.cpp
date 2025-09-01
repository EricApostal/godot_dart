#include <gdextension_interface.h>

#include <godot_cpp/classes/editor_plugin_registration.hpp>
#include <godot_cpp/classes/object.hpp>

#include "dart_bindings.h"
#include "dart_helpers.h"
#include "gde_wrapper.h"
#include "godot_dart_runtime_plugin.h"
#include "godot_string_wrappers.h"

#include "dart_instance_binding.h"
#include "ref_counted_wrapper.h"
namespace godot_dart {

void initialize_level(godot::ModuleInitializationLevel p_level) {
  if (p_level == godot::ModuleInitializationLevel::MODULE_INITIALIZATION_LEVEL_EDITOR) {
  }

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
}
