#import "Request.h"
#import "Service.h"
#import "Constants.h"

@implementation Request
{
  NSString * __taskId;
  NSString * __targetPath;
  NSString * __targetDir;
  NSString * __strData;
  NSData * __data;
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
    self.charset = nil;
    self.dataType = TEXT;
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
  NSString * strExt = options[[Constants EXTENSION]];
  NSDictionary * dictHeaders = options[[Constants HEADERS]];
  NSNumber * nAccessible = options[[Constants ACCESSIBLE]];
  NSNumber * nRewrite = options[[Constants REWRITE]];
  NSString * strSign = options[[Constants SIGN]];
  NSString * strDataType = options[[Constants DATA_TYPE]];
  NSString * strCharset = options[[Constants DATA_CHARSET]];
  
  NSString * strData = options[[Constants DATA]];
  if(strData && ![strData isKindOfClass:[NSNull class]]){
    __strData = options[[Constants DATA]];
  }
  else {
    __strData = nil;
  }
  
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
  if(strExt && [strExt isKindOfClass:[NSString class]])
  {
    self.extension=[strExt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if([self.extension length])
    {
      if([self.extension characterAtIndex:0]!='.')
      {
        self.extension = [@"." stringByAppendingString:self.extension];
      }
    }
  }
  if(nRewrite && [nRewrite isKindOfClass:[NSNumber class]])
  {
    self.rewrite=[nRewrite boolValue];
  }
  if(__strData && [__strData isKindOfClass:[NSString class]])
  {
    if(strSign && [strSign isKindOfClass:[NSString class]])
    {
      self.sign = strSign;
    }
    if(strCharset && [strCharset isKindOfClass:[NSString class]])
    {
      self.charset = strCharset;
    }
    if(strDataType && [strDataType isKindOfClass:[NSString class]])
    {
      if([strDataType isEqualToString:@"text"]) {
        self.dataType = TEXT;
      } else if([strDataType isEqualToString:@"base64"]) {
        self.dataType = BASE64;
      } else if([strDataType isEqualToString:@"base64URL"]) {
        self.dataType = BASE64_URL;
      }
    }
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
  __taskId = [Service selectTaskId:self.id url:self.url sign:self.sign];
  return __taskId;
}

- (NSString *)generateTargetFilePath
{
  if(!__targetPath)
  {
    __targetPath = [Service generateTargetFilePath:self.targetDir subDir:self.subDir taskId:[self selectTaskId] url:self.extension];
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

- (NSData *)getData
{
  if(!__strData){
    return nil;
  }
  
  if(!self.data)
  {
    if(self.dataType == BASE64)
    {
      self.data = [[NSData alloc] initWithBase64EncodedString:__strData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    } else if(_dataType ==BASE64_URL) {
      // 编码
      // '+' -> '-'
      // '/' -> '_'
      // '=' -> ''
      
      // 解码
      NSString * base64Str = [Service safeUrlBase64Decode:__strData];
      self.data = [[NSData alloc] initWithBase64EncodedString:base64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    } else {
      NSStringEncoding encoding = NSUTF8StringEncoding;
      if(self.charset)
      {
        CFStringRef charsetRef = (__bridge CFStringRef)self.charset;
        CFStringEncoding cfStingEncoding =  CFStringConvertIANACharSetNameToEncoding(charsetRef);
        if(cfStingEncoding != kCFStringEncodingInvalidId)
        {
          encoding = CFStringConvertEncodingToNSStringEncoding(cfStingEncoding);
        }
      }
      self.data = [__strData dataUsingEncoding:encoding];
    }
  }
  
  return self.data;
}

@end

