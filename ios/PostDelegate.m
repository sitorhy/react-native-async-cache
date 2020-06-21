#import "PostDelegate.h"
#import "Constants.h"
#import "Service.h"

static double STEP = 0.036;

@implementation PostDelegate
{
  int64_t total;
  int64_t current;
  double progress;
}

- (instancetype)init:(Request *)request resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject reportProgress:(BOOL)needCalculateProgress emitter:(id<CacheEmitter>)sender
{
  self = [super init];
  self.request = request;
  self.emitter = sender;
  self.needCalculateProgress = needCalculateProgress;
  self.resolver = resolve;
  self.rejecter = reject;
  total = -1;
  current = 0;
  progress = 0;
  return self;
}

- (void)resolve:(NSString *)url targetPath:(NSString *)targetPath size:(int64_t)total
{
  if(self.resolver)
  {
    self.resolver(@{
      [Constants PATH]:targetPath,
      [Constants SIZE]:@(total),
      [Constants URL]:self.request.url
                  });
    self.resolver = nil;
    self.resolver = nil;
  }
}

- (void)reject:(NSString *)code message:(NSString *)message error:(NSError * _Nullable)error
{
  if(self.rejecter)
  {
    self.rejecter(code, message, error);
    self.resolver = nil;
    self.rejecter = nil;
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  if(current <= 0)
  {
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    NSString * targetPath = [self.request generateTargetFilePath];
    if([defaultManager fileExistsAtPath:targetPath])
    {
      [session invalidateAndCancel];
    }
  }
  if(self.needCalculateProgress)
  {
    total = totalBytesExpectedToWrite;
    current = totalBytesWritten;
    
    double nextProgress = (double)current/(double)total;
    
    if (nextProgress == 1.0 || progress + STEP < nextProgress) {
      progress = nextProgress;
      [self.emitter emitProgressEvent:self.request.url didWriteData:current totalBytesWritten:total];
    }
  }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
  NSFileManager * defaultManager = [NSFileManager defaultManager];
  NSError * error;
  NSString * targetPath = [self.request generateTargetFilePath];
  NSString * sourcePath =  location.path;
  
  @try {
    BOOL sourceExists = [defaultManager fileExistsAtPath:sourcePath];
    if(!sourceExists){
      NSString * sessionCacheFileName = [location.path lastPathComponent];
      NSArray<NSString *> * domains = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, TRUE);
      NSString * cacheDomain = domains.firstObject;
      NSDirectoryEnumerator * tempEnum =  [defaultManager enumeratorAtPath:cacheDomain];
      NSString * relative;
      while ((relative = [tempEnum nextObject])) {
        if ([[relative lastPathComponent] isEqualToString: sessionCacheFileName]) {
          sourcePath = [cacheDomain stringByAppendingPathComponent:relative];
          if(![defaultManager fileExistsAtPath:targetPath]){
            [defaultManager moveItemAtPath:sourcePath toPath:targetPath error:nil];
            [session finishTasksAndInvalidate];
          }
          return;
        }
      }
    }
    if(![defaultManager fileExistsAtPath:targetPath])
      [defaultManager moveItemAtPath:sourcePath toPath:targetPath error:&error];
    if(!error)
    {
      [session finishTasksAndInvalidate];
      [self.emitter emitPostedEvent:self.request.url targetPath:targetPath fileSize:total errorCode:0 errorMessage:nil taskId:[self.request selectTaskId]];
    }
    else
    {
      [session invalidateAndCancel];
      [defaultManager removeItemAtPath:sourcePath error:nil];
      [self.emitter onPostedError:error taskId:[self.request selectTaskId]];
      [self reject:[NSString stringWithFormat:@"%ld",(long)error.code] message:error.localizedDescription error:error];
    }
  } @catch (NSException * exception) {
    [session invalidateAndCancel];
    [defaultManager removeItemAtPath:sourcePath error:nil];
    [self.emitter onPostedExecption:exception taskId:[self.request selectTaskId]];
    [self reject:@"-1" message:exception.name error:nil];
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  if(error)
  {
    if(error.userInfo)
    {
      NSData * resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
      if(resumeData)
      {
        NSURLSessionDownloadTask * task = [session downloadTaskWithResumeData:resumeData];
        [task resume];
      }
    }
    else
    {
      [self.emitter onPostedError:error taskId:[self.request selectTaskId]];
      [self reject:@"-1" message:error.localizedDescription error:error];
    }
  }
  else
  {
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    NSString * targetPath = [self.request generateTargetFilePath];
    if([defaultManager fileExistsAtPath:targetPath])
    {
      NSError * err;
      NSDictionary<NSFileAttributeKey, id> * attrs = [defaultManager attributesOfItemAtPath:targetPath error:&err];
      if(!err)
      {
        [self resolve:self.request.url targetPath:[self.request generateTargetFilePath] size:[attrs fileSize]];
      }
      else
      {
        [self.emitter onPostedError:err taskId:[self.request selectTaskId]];
        [self reject:@"-1" message:error.localizedDescription error:err];
      }
    }
  }
}

@end
