/* Prints the size every interface structure really has, straight from
 * Godot's header. Paired with iface_sizes.pb by tools/check-interface.sh. */
#include <stdio.h>
#include "gdextension_interface.h"
int main(void) {
  printf("GDExtensionCallError %zu\n", sizeof(GDExtensionCallError));
  printf("GDExtensionInstanceBindingCallbacks %zu\n", sizeof(GDExtensionInstanceBindingCallbacks));
  printf("GDExtensionPropertyInfo %zu\n", sizeof(GDExtensionPropertyInfo));
  printf("GDExtensionMethodInfo %zu\n", sizeof(GDExtensionMethodInfo));
  printf("GDExtensionClassCreationInfo %zu\n", sizeof(GDExtensionClassCreationInfo));
  printf("GDExtensionClassCreationInfo2 %zu\n", sizeof(GDExtensionClassCreationInfo2));
  printf("GDExtensionClassCreationInfo3 %zu\n", sizeof(GDExtensionClassCreationInfo3));
  printf("GDExtensionClassCreationInfo4 %zu\n", sizeof(GDExtensionClassCreationInfo4));
  printf("GDExtensionClassMethodInfo %zu\n", sizeof(GDExtensionClassMethodInfo));
  printf("GDExtensionClassVirtualMethodInfo %zu\n", sizeof(GDExtensionClassVirtualMethodInfo));
  printf("GDExtensionCallableCustomInfo %zu\n", sizeof(GDExtensionCallableCustomInfo));
  printf("GDExtensionCallableCustomInfo2 %zu\n", sizeof(GDExtensionCallableCustomInfo2));
  printf("GDExtensionScriptInstanceInfo %zu\n", sizeof(GDExtensionScriptInstanceInfo));
  printf("GDExtensionScriptInstanceInfo2 %zu\n", sizeof(GDExtensionScriptInstanceInfo2));
  printf("GDExtensionScriptInstanceInfo3 %zu\n", sizeof(GDExtensionScriptInstanceInfo3));
  printf("GDExtensionInitialization %zu\n", sizeof(GDExtensionInitialization));
  printf("GDExtensionGodotVersion %zu\n", sizeof(GDExtensionGodotVersion));
  printf("GDExtensionGodotVersion2 %zu\n", sizeof(GDExtensionGodotVersion2));
  printf("GDExtensionMainLoopCallbacks %zu\n", sizeof(GDExtensionMainLoopCallbacks));
  return 0;
}
