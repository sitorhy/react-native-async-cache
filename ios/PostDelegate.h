#import <Foundation/Foundation.h>
#import "Request.h"
#import "CacheEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostDelegate : NSObject<NSURLSessionDownloadDelegate>

@property(nonatomic,nullable) Request * request;

@property(nonatomic,nullable) id<CacheEmitter> emitter;

@property(nonatomic,nullable) RCTPromiseRejectBlock rejecter;

@property(nonatomic,nullable) RCTPromiseResolveBlock resolver;

@property(nonatomic) BOOL needCalculateProgress;

- (instancetype)init:(Request *)request resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject reportProgress:(BOOL)needCalculateProgress emitter:(id<CacheEmitter>)sender;

- (void)resolve:(NSString *)url targetPath:(NSString *)targetPath size:(int64_t)total;

- (void)reject:(NSString *)code message:(NSString *)message error:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
