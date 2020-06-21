#import "Request.h"
#import "Service.h"
#import "Constants.h"

@implementation Request
{
  NSString * __taskId;
  NSString * __targetPath;
  NSString * __targetDir;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.statusCodeLeft = 200;
    self.statusCodeRight = 300;
    self.timeout = 3;
    self.subDir = @"";
    self.targetDir = @"";
    self.id = @"";
    self.url = @"";
    self.headers = nil;
  }
  return self;
}

- (instancetype)init:(NSDictionary *)options
{
  self = [self init];
  
  NSNumber * nStatusCodeLeft = options[[Constants STATUS_CODE_LEFT]];
  NSNumber * nStatusCodeRight = options[[Constants STATUS_CODE_RIGHT]];
  NSNumber * nTimeout = options[[Constants TIME_OUT]];
  NSString * strSubDir = options[[Constants SUB_DIR]];
  NSString * strTargetDir = options[[Constants TARGET_DIR]];
  NSString * strID = options[[Constants ID]];
  NSString * strURL = options[[Constants URL]];
  NSDictionary * dictHeaders = options[[Constants HEADERS]];
  NSNumber * nAccessible = options[[Constants ACCESSIBLE]];
  NSNumber * nRewrite = options[[Constants REWRITE]];
  
  if(nStatusCodeLeft && [nStatusCodeLeft isKindOfClass:[NSNumber class]])
  {
    self.statusCodeLeft=[nStatusCodeLeft longValue];
  }
  if(nStatusCodeRight && [nStatusCodeRight isKindOfClass:[NSNumber class]])
  {
    self.statusCodeRight=[nStatusCodeRight longValue];
  }
  if(nTimeout && [nTimeout isKindOfClass:[NSNumber class]])
  {
    self.timeout=[nTimeout longValue] / 1000;
  }
  if(strSubDir && [strSubDir isKindOfClass:[NSString class]])
  {
    self.subDir=strSubDir;
  }
  if(strTargetDir && [strTargetDir isKindOfClass:[NSString class]])
  {
    self.targetDir=strTargetDir;
  }
  if(strID && [strID isKindOfClass:[NSString class]])
  {
    self.id=strID;
  }
  if(strURL && [strURL isKindOfClass:[NSString class]])
  {
    self.url=strURL;
  }
  if(dictHeaders && [dictHeaders isKindOfClass:[NSDictionary class]])
  {
    self.headers=dictHeaders;
  }
  if(nAccessible && [nAccessible isKindOfClass:[NSNumber class]])
  {
    self.accessible=[nAccessible boolValue];
  }
  if(nRewrite && [nRewrite isKindOfClass:[NSNumber class]])
  {
    self.rewrite=[nRewrite boolValue];
  }
  
  return self;
}

- (NSString *)selectTaskId
{
  if (self.id != nil && [self.id length]>0) {
    return self.id;
  }
  if (__taskId != nil && [__taskId length]>0) {
    return __taskId;
  }
  __taskId = [Service selectTaskId:self.id url:self.url];
  return __taskId;
}

- (NSString *)generateTargetFilePath
{
  if(!__targetPath)
  {
    __targetPath = [Service generateTargetFilePath:self.targetDir subDir:self.subDir taskId:[self selectTaskId] url:self.url];
  }
  return __targetPath;
}

- (NSString *)generateTargetDirectoryPath
{
  if(!__targetDir)
  {
    __targetDir = [Service generateTargetDirectoryPath:self.targetDir subDir:self.subDir];
  }
  return __targetDir;
}

- (BOOL)validateRequest:(RCTPromiseRejectBlock)reject
{
  if (!self.url || ![self.url length]) {
    if (reject != nil) {
      reject(@"-1",@"url not allow empty", nil);
    }
    return FALSE;
  }
  if (![self.url hasPrefix:@"http"]) {
    if (reject != nil) {
      reject(@"-1",@"url is not a http link", nil);
    }
    return FALSE;
  }
  return TRUE;
}

- (void)checkUrlAccessible:(AccessibleCallback)callback;
{
  [Service checkUrlAccessible:self.accessibleMethod url:self.url requestHeaders:self.headers statusCodeLeft:self.statusCodeLeft statusCodeRight:self.statusCodeRight timeout:self.timeout accessibleReceiveCallback:callback];
}

@end

