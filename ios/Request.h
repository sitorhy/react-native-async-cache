#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "AccessibleResult.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^AccessibleCallback)(AccessibleResult * accessible);

@interface Request : NSObject

-(instancetype)init:(NSDictionary *)options;

@property(nonatomic) NSString * accessibleMethod;

@property(nonatomic) NSInteger statusCodeLeft;

@property(nonatomic) NSInteger statusCodeRight;

@property(nonatomic) NSInteger timeout;

@property(nonatomic) NSString * subDir;

@property(nonatomic) NSString * targetDir;

@property(nonatomic) NSString * id;

@property(nonatomic) NSString * url;

@property(nonatomic,nullable) NSDictionary * headers;

@property(nonatomic) BOOL accessible;

@property(nonatomic) BOOL rewrite;

- (NSString *)selectTaskId;

- (NSString *)generateTargetFilePath;

- (NSString *)generateTargetDirectoryPath;

- (BOOL)validateRequest:(RCTPromiseRejectBlock _Nullable)reject;

- (void)checkUrlAccessible:(AccessibleCallback)callback;

@end

NS_ASSUME_NONNULL_END
