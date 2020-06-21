#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

#import "CacheEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReactNativeAsyncCacheModule : RCTEventEmitter<RCTBridgeModule,CacheEmitter>

@end

NS_ASSUME_NONNULL_END
