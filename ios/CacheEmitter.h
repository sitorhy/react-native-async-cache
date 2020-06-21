#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CacheEmitter <NSObject>

- (void)emitProgressEvent:(NSString *)url didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten;

- (void)emitPostedEvent:(NSString *)url targetPath:(NSString *)targetPath fileSize:(int64_t)totalBytes errorCode:(long)statusCode errorMessage:(NSString * _Nullable)message taskId:(NSString *)taskId;

- (void)onPostedExecption:(NSException *)exception taskId:(NSString *)taskId;

- (void)onPostedError:(NSError *)error taskId:(NSString *)taskId;

- (void)signTask:(NSString *)taskId;

- (void)unsignTask:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END
