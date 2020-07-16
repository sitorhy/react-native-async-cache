#import <CommonCrypto/CommonDigest.h>
#import "Service.h"

static NSString * USER_AGENT = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36";

static NSString * TASK_ID_PREFIX = @"rn_async_cache-";

@implementation Service

+ (NSString *)MODULE_DIR_NAME
{
  return @"RNAsyncCache";
}

+ (NSString *)md5:(NSString *) str
{
  const char * cStr = [str UTF8String];
  unsigned char result[16];
  CC_MD5(cStr,(uint32_t)strlen(cStr),result);
  return([NSString stringWithFormat:
          @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          result[0], result[1], result[2], result[3],
          result[4], result[5], result[6], result[7],
          result[8], result[9], result[10], result[11],
          result[12], result[13], result[14], result[15]]);
}

+ (NSString *)getTargetDirectoryPath
{
  NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:[self MODULE_DIR_NAME]];
  NSFileManager * fileManager = [NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:documentPath])
  {
    [fileManager createDirectoryAtPath:documentPath withIntermediateDirectories:TRUE attributes:nil error:nil];
  }
  return documentPath;
}

+ (NSString *)getTempDirectoryPath
{
  NSString * cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
  return cachePath;
}

+ (NSString *)selectTaskId:(NSString *)taskId url:(NSString *)url sign:(NSString *)sign
{
  if (taskId != nil && [taskId length]>0) {
    return taskId;
  }
  if(sign && sign.length >0)
  {
    return [self md5:[url stringByAppendingString:sign]];
  }
  else
  {
    return [self md5:url];
  }
}

+ (NSString *) getUrlExtension:(NSString * _Nullable)url
{
  if(url)
  {
    NSString * str = url;
    NSRange rangeQue = [str rangeOfString:@"?" options:NSBackwardsSearch];
    if(rangeQue.location != NSNotFound)
    {
      str = [str substringWithRange:(NSRange){0,rangeQue.location}];
    }
    NSRange rangeSep = [str rangeOfString:@"/" options:NSBackwardsSearch];
    if(rangeSep.location != NSNotFound)
    {
      str = [str substringWithRange:(NSRange){rangeSep.location+1,str.length-rangeSep.location-1}];
    }
    NSRange rangeDot = [str rangeOfString:@"." options:NSBackwardsSearch];
    if(rangeDot.location != NSNotFound)
    {
      NSString * dotExt = [str substringWithRange:(NSRange){rangeDot.location,str.length-rangeDot.location}];
      return dotExt;
    }
  }
  return @"";
}

+ (NSString *)generateTargetFileName:(NSString *)taskId extractExtFromUrl:(NSString *)extension
{
  NSString * ext = [self getUrlExtension:extension];
  return [taskId stringByAppendingString:ext];
}

+ (NSString *)generateTargetDirectoryPath:(NSString *)targetDir subDir:(NSString *)subDir
{
  NSString  * dir;
  if(subDir && [subDir length]>0)
  {
    dir = [targetDir stringByAppendingPathComponent:subDir];
  }
  else
  {
    dir = targetDir;
  }
  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath:dir])
  {
    [fileManager createDirectoryAtPath:dir withIntermediateDirectories:TRUE attributes:nil error:nil];
  }
  
  return dir;
}

+ (NSString *)generateTargetFilePath:(NSString *)targetDir subDir:(NSString *)subDir taskId:(NSString *)taskId url:(NSString * _Nullable)url
{
  NSString * dir = [self generateTargetDirectoryPath:targetDir subDir:subDir];
  return [dir stringByAppendingPathComponent:[self generateTargetFileName:taskId extractExtFromUrl:url]];
}

+ (void)checkUrlAccessible:(NSString *)method url:(nonnull NSString *)url requestHeaders:(NSDictionary *)headers statusCodeLeft:(long)statusCodeLeft statusCodeRight:(long)statusCodeRight timeout:(long)seconds accessibleReceiveCallback:(AccessibleCallback)callback;
{
  NSURL * requestUrl = [NSURL URLWithString:url];
  NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:requestUrl];
  NSURLSession * session = [NSURLSession sharedSession];
  
  if(method == nil)
    request.HTTPMethod = @"HEAD";
  else
    request.HTTPMethod = method;
  [request addValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
  [request addValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
  [request setTimeoutInterval:seconds];
  NSURLSessionDataTask * task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if(response)
    {
      NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
      long statusCode = httpResponse.statusCode;
      NSString * contentType = httpResponse.MIMEType;
      AccessibleResult * result = [[AccessibleResult alloc] init:statusCode responseErrorDescription:[NSHTTPURLResponse localizedStringForStatusCode:statusCode] contentType:contentType urlAccessible:statusCodeLeft <= httpResponse.statusCode && httpResponse.statusCode <= statusCodeRight];
      result.size = httpResponse.expectedContentLength;
      callback(result);
    }
    else
    {
      AccessibleResult * result = [[AccessibleResult alloc] init:error.code responseErrorDescription:error.localizedDescription contentType:@"" urlAccessible:FALSE];
      result.size = -1;
      callback(result);
    }
  }];
  [task resume];
}

+ (void)download:(NSString *)taskId delegate:(PostDelegate *)delegate url:(NSString *)url requestHeaders:(NSDictionary *)headers;
{
  NSURL * requestUrl = [[NSURL alloc] initWithString:url];
  NSURLSessionConfiguration * config;
  NSString * uniqueSessionId = [TASK_ID_PREFIX stringByAppendingString:taskId];
  config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:uniqueSessionId];
  NSURLSession * session = [NSURLSession sessionWithConfiguration:config delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
  NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
  [request addValue:USER_AGENT forHTTPHeaderField:@"User-Agent"];
  [request addValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
  NSURLSessionTask * task = [session downloadTaskWithRequest:request];
  [task resume];
}

- (NSString*)safeUrlBase64Decode:(NSString*)safeUrlbase64Str
{
    // '-' -> '+'
    // '_' -> '/'
    // 不足4倍长度，补'='
    NSMutableString * base64Str = [[NSMutableString alloc]initWithString:safeUrlbase64Str];
    base64Str = (NSMutableString * )[base64Str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    base64Str = (NSMutableString * )[base64Str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    NSInteger mod4 = base64Str.length % 4;
    if(mod4 > 0)
        [base64Str appendString:[@"====" substringToIndex:(4-mod4)]];
    return base64Str;
}

@end
