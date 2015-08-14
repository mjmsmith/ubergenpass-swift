
// To check if a library is compiled with CocoaPods you
// can use the `COCOAPODS` macro definition which is
// defined in the xcconfigs so it is available in
// headers also when they are imported in the client
// project.


// Crashlytics
#define COCOAPODS_POD_AVAILABLE_Crashlytics
#define COCOAPODS_VERSION_MAJOR_Crashlytics 3
#define COCOAPODS_VERSION_MINOR_Crashlytics 1
#define COCOAPODS_VERSION_PATCH_Crashlytics 0

// Fabric
#define COCOAPODS_POD_AVAILABLE_Fabric
#define COCOAPODS_VERSION_MAJOR_Fabric 1
#define COCOAPODS_VERSION_MINOR_Fabric 2
#define COCOAPODS_VERSION_PATCH_Fabric 8

// Fabric/Base
#define COCOAPODS_POD_AVAILABLE_Fabric_Base
#define COCOAPODS_VERSION_MAJOR_Fabric_Base 1
#define COCOAPODS_VERSION_MINOR_Fabric_Base 2
#define COCOAPODS_VERSION_PATCH_Fabric_Base 8

// Debug build configuration
#ifdef DEBUG

  // Reveal-iOS-SDK
  #define COCOAPODS_POD_AVAILABLE_Reveal_iOS_SDK
  #define COCOAPODS_VERSION_MAJOR_Reveal_iOS_SDK 1
  #define COCOAPODS_VERSION_MINOR_Reveal_iOS_SDK 5
  #define COCOAPODS_VERSION_PATCH_Reveal_iOS_SDK 1

#endif
