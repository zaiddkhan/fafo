#if __has_include(<maplibre_ios/maplibre_ios-Swift.h>)
#import <maplibre_ios/maplibre_ios-Swift.h>
#else
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>

@interface MapLibrePlugin : NSObject <FlutterPlugin>
+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar;
@end
#endif
