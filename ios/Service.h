#import <Foundation/Foundation.h>
#import "AccessibleResult.h"
#import "PostDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface Service : NSObject

+ (NSString *) getTempDirectoryPath;

+ (NSString *) getTargetDirectoryPath;

+ (NSString *) selectTaskId:(NSString *)id url:(NSString *)url;

+ (NSString *) generateTargetFileName:(NSString *)taskId extractExtFromUrl:(NSString *)extension;

+ (NSString *) generateTargetDirectoryPath:(NSString *)targetDir subDir:(NSString *)subDir;

+ (NSString *) getUrlExtension:(NSString * _Nullable)url;

+ (NSString *) generateTargetFilePath:(NSString *)targetDir subDir:(NSString *)subDir taskId:(NSString *)taskId url:(NSString * _Nullable)url;

+ (void)checkUrlAccessible:(NSString *)method url:(nonnull NSString *)url requestHeaders:(NSDictionary *)headers statusCodeLeft:(long)statusCodeLeft statusCodeRight:(long)statusCodeRight timeout:(long)seconds accessibleReceiveCallback:(AccessibleCallback)callback;

+ (void)download:(NSString *)taskId delegate:(PostDelegate *)delegate url:(NSString *)url requestHeaders:(NSDictionary *)headers;

@end

NS_ASSUME_NONNULL_END
