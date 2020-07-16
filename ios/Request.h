#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "AccessibleResult.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^AccessibleCallback)(AccessibleResult * accessible);

typedef enum : NSUInteger {
  TEXT,
  BASE64,
  BASE64_URL,
} DataType;

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

@property(nonatomic) NSString * extension;

@property(nonatomic) DataType dataType;

@property(nonatomic,nullable) NSData * data;

@property(nonatomic,nullable) NSString * sign;

@property(nonatomic,nullable) NSString * charset;

- (NSString *)selectTaskId;

- (NSString *)generateTargetFilePath;

- (NSString *)generateTargetDirectoryPath;

- (BOOL)validateRequest:(RCTPromiseRejectBlock _Nullable)reject;

- (void)checkUrlAccessible:(AccessibleCallback)callback;

- (NSData *)getData;

@end

NS_ASSUME_NONNULL_END
