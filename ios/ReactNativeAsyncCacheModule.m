#import "ReactNativeAsyncCacheModule.h"
#import "Constants.h"
#import "Service.h"
#import "Request.h"
#import "PostDelegate.h"

@implementation ReactNativeAsyncCacheModule
{
  NSOperationQueue * operationQueue;
  NSLock * taskLock;
  NSMutableSet<NSString *> * tasksSet;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    taskLock = [[NSLock alloc] init];
    tasksSet = [[NSMutableSet alloc] init];
    operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 24;
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return TRUE;
}

- (NSDictionary *)constantsToExport
{
  NSDictionary * constants = @{
    [Constants TEMP_DIR]:[Service getTempDirectoryPath],
    [Constants DOC_DIR]:[Service getTargetDirectoryPath]
  };
  return constants;
}

- (BOOL)existsTask:(NSString *)taskId
{
  BOOL exists;
  [taskLock lock];
  exists = [tasksSet containsObject:taskId];
  [taskLock unlock];
  return exists;
}

- (void)signTask:(NSString *)taskId
{
  [taskLock lock];
  [tasksSet addObject:taskId];
  [taskLock unlock];
}

- (void)unsignTask:(NSString *)taskId
{
  [taskLock lock];
  [tasksSet removeObject:taskId];
  [taskLock unlock];
}

RCT_EXPORT_MODULE(ReactNativeAsyncCache);

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"RNAsyncCachePosted",@"RNAsyncCacheProgress"];
}

- (void) clean:(NSString *)removeDir deleteDirSelf:(BOOL)deleteItself
{
  if(!removeDir)
  {
    return;
  }
  NSFileManager * defaultManager = [NSFileManager defaultManager];
  BOOL isDir;
  BOOL exists = [defaultManager fileExistsAtPath:removeDir isDirectory:&isDir];
  if(exists && isDir)
  {
    NSArray * contents = [defaultManager contentsOfDirectoryAtPath:removeDir error:nil];
    NSEnumerator * e = [contents objectEnumerator];
    NSString * file;
    while ((file = [e nextObject])) {
      exists = [defaultManager fileExistsAtPath:file isDirectory:&isDir];
      if(exists)
      {
        if(isDir)
        {
          [self clean:file deleteDirSelf:TRUE];
        }
        else
        {
          [defaultManager removeItemAtPath:file error:nil];
        }
      }
    }
    
    if(deleteItself)
    {
      [defaultManager removeItemAtPath:removeDir error:nil];
    }
  }
}

- (void) download:(Request *)request resolver:(RCTPromiseResolveBlock _Nullable)resolve rejecter:(RCTPromiseRejectBlock _Nullable)reject reportProgress:(BOOL)needCalculateProgress {
  NSString * taskId = [request selectTaskId];
  if(resolve && reject) // not null from RCTMethod "download", the task has been locked before RCTMethod "post"
  {
    if([self existsTask:taskId])
    {
      return;
    }
  }
  NSFileManager * defaultManager = [NSFileManager defaultManager];
  NSString * targetPath =  [request generateTargetFilePath];
  BOOL isDir;
  if([defaultManager fileExistsAtPath:targetPath isDirectory:&isDir])
  {
    NSError * error = nil;
    NSDictionary<NSFileAttributeKey, id> * attrs = [defaultManager attributesOfItemAtPath:targetPath error:&error];
    if(!error)
    {
      if(request.rewrite || isDir)
      {
        [defaultManager removeItemAtPath:targetPath error:&error];
        if(reject && error)
        {
          reject([NSString stringWithFormat:@"%ld",(long)error.code],error.localizedDescription,error);
        }
        else
        {
          [self signTask:taskId];
          PostDelegate * delegate = [[PostDelegate alloc] init:request resolver:resolve rejecter:reject reportProgress:needCalculateProgress emitter:self];
          [Service download:[request selectTaskId] delegate:delegate url:request.url requestHeaders:request.headers];
        }
      }
      else
      {
        if(resolve)
        {
          resolve(@{
            [Constants PATH]:targetPath,
            [Constants SIZE]:@([attrs fileSize]),
            [Constants URL]:request.url
                  });
        }
        [self emitPostedEvent:request.url targetPath:targetPath fileSize:[attrs fileSize] errorCode:0 errorMessage:nil taskId:taskId];
      }
    }
    else
    {
      if(reject)
      {
        reject([NSString stringWithFormat:@"%ld",(long)error.code],error.localizedDescription,error);
      }
    }
  }
  else
  {
    [self signTask:taskId];
    PostDelegate * delegate = [[PostDelegate alloc] init:request resolver:resolve rejecter:reject reportProgress:needCalculateProgress emitter:self];
    [Service download:[request selectTaskId] delegate:delegate url:request.url requestHeaders:request.headers];
  }
}

- (void)post:(Request *)request
{
  if (![request validateRequest:nil])
  {
    return;
  }
  NSString * taskId = [request selectTaskId];
  if([self existsTask:taskId])
  {
    return;
  }
  [self signTask:taskId];
  [operationQueue addOperationWithBlock:^{
    NSData * data;
    NSString * targetPath = [request generateTargetFilePath];
    
    @try {
      data = [request getData];
    } @catch (NSException *exception) {
      [self emitPostedEvent:request.url targetPath:targetPath fileSize:-1 errorCode:-1 errorMessage:exception.name taskId:taskId];
      return;
    }
    
    if(!data)
    {
      [request checkUrlAccessible:^(AccessibleResult * _Nonnull accessible) {
        if(accessible.accessible)
        {
          NSFileManager * defaultManager = [NSFileManager defaultManager];
          BOOL isDir;
          BOOL exists = [defaultManager fileExistsAtPath:targetPath isDirectory:&isDir];
          if(exists)
          {
            NSError * error = nil;
            NSDictionary<NSFileAttributeKey, id> * attrs = nil;
            if(request.rewrite || isDir)
            {
              [defaultManager removeItemAtPath:targetPath error:&error];
            }
            else
            {
              attrs = [defaultManager attributesOfItemAtPath:targetPath error:&error];
            }
            if(error)
            {
              [self emitPostedEvent:request.url targetPath:targetPath fileSize:-1 errorCode:error.code errorMessage:error.localizedDescription taskId:taskId];
            }
            else if(attrs)
            {
              [self emitPostedEvent:request.url targetPath:targetPath fileSize:[attrs fileSize] errorCode:0 errorMessage:nil taskId:taskId];
              return;
            }
          }
          [self download:request resolver:nil rejecter:nil reportProgress:FALSE];
        }
        else
        {
          [self emitPostedEvent:request.url targetPath:@"" fileSize:-1 errorCode:accessible.responseCode errorMessage:accessible.message taskId:taskId];
        }
      }];
    }
    else
    {
      @try {
        [data writeToFile:targetPath atomically:TRUE];
      } @catch (NSException *exception) {
        [self emitPostedEvent:request.url targetPath:targetPath fileSize:-1 errorCode:-1 errorMessage:exception.name taskId:taskId];
      }
    }
  }];
}

RCT_REMAP_METHOD(post,createPostRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if (![request validateRequest:nil]) {
    return;
  }
  [self post:request];
}

RCT_REMAP_METHOD(download,createDownloadRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if (![request validateRequest:nil]) {
    return;
  }
  [self download:request resolver:resolve rejecter:reject reportProgress:TRUE];
}

RCT_REMAP_METHOD(accessible,createAccessibleRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if (![request validateRequest:nil]) {
    return;
  }
  [operationQueue addOperationWithBlock:^{
    [request checkUrlAccessible:^(AccessibleResult * _Nonnull accessible) {
      resolve(@{
        [Constants MESSAGE]:accessible.message,
        [Constants STATUS_CODE]:@(accessible.responseCode),
        [Constants CONTENT_TYPE]:accessible.contentType ? accessible.contentType : @"",
        [Constants ACCESSIBLE]:[[NSNumber alloc] initWithBool:accessible.accessible],
        [Constants SIZE]:@(accessible.size),
        [Constants URL]:request.url
              });
    }];
  }];
}

RCT_REMAP_METHOD(trash,createTrashRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  [operationQueue addOperationWithBlock:^{
    @try {
      [self clean:[request generateTargetDirectoryPath] deleteDirSelf:request.subDir!=nil && request.subDir.length];
      resolve(nil);
    } @catch (NSException *exception) {
      reject(@"-1",exception.reason,nil);
    }
  }];
}

RCT_REMAP_METHOD(clean,resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  [operationQueue addOperationWithBlock:^{
    @try {
      [self clean:[Service getTempDirectoryPath] deleteDirSelf:FALSE];
      resolve(nil);
    } @catch (NSException *exception) {
      reject(@"-1",exception.reason,nil);
    }
  }];
}

RCT_REMAP_METHOD(remove,createRemoveRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if (![request validateRequest:reject]) {
    return;
  }
  [operationQueue addOperationWithBlock:^{
    NSString * targetPath = [request generateTargetFilePath];
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [defaultManager fileExistsAtPath:targetPath isDirectory:&isDir];
    if(!isDir && exists)
    {
      NSFileManager * defaultManager = [NSFileManager defaultManager];
      BOOL success = [defaultManager removeItemAtPath:targetPath error:nil];
      resolve(@{
        [Constants EXISTS]:[[NSNumber alloc] initWithBool:success],
        [Constants URL]:request.url,
        [Constants PATH]:targetPath
              });
    }
    else
    {
      resolve(@{
        [Constants SUCCESS]:[[NSNumber alloc] initWithBool:FALSE],
        [Constants URL]:request.url
              });
    }
  }];
}

RCT_REMAP_METHOD(check,createCheckRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if (![request validateRequest:reject]) {
    return;
  }
  [operationQueue addOperationWithBlock:^{
    NSString * targetPath = [request generateTargetFilePath];
    NSFileManager * defaultManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [defaultManager fileExistsAtPath:targetPath isDirectory:&isDir];
    if(exists)
    {
      if(!isDir)
      {
        NSError * error;
        NSDictionary<NSFileAttributeKey, id> * attrs = [defaultManager attributesOfItemAtPath:targetPath error:&error];
        if(error || !attrs || ![attrs fileSize])
        {
          resolve(@{
            [Constants EXISTS]:[[NSNumber alloc] initWithBool:FALSE],
            [Constants URL]:request.url
                  });
        }
        else
        {
          resolve(@{
            [Constants EXISTS]:[[NSNumber alloc] initWithBool:TRUE],
            [Constants URL]:request.url,
            [Constants PATH]:targetPath
                  });
        }
      }
      else
      {
        resolve(@{
          [Constants EXISTS]:[[NSNumber alloc] initWithBool:FALSE],
          [Constants URL]:request.url
                });
      }
    }
    else
    {
      resolve(@{
        [Constants EXISTS]:[[NSNumber alloc] initWithBool:FALSE],
        [Constants URL]:request.url
              });
    }
  }];
}

- (void)rejectSelect:(RCTPromiseResolveBlock)resolve writeableResp:(NSMutableDictionary *)response requestAddress:(NSString *)url
{
  [response setObject:url forKey:[Constants URL]];
  [response setObject:[[NSNumber alloc] initWithBool:FALSE] forKey:[Constants SUCCESS]];
  resolve(response);
}

RCT_REMAP_METHOD(select,createSelectRequestWithOptions:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  Request * request = [[Request alloc] init:options];
  if(![request validateRequest:reject])
  {
    return;
  }
  
  NSData * data;
  @try {
    data = [request getData];
  } @catch (NSException * exception) {
    NSMutableDictionary * resp = [[NSMutableDictionary alloc] init];
    [resp setObject:exception.name forKey:[Constants MESSAGE]];
    [resp setObject:@(-1) forKey:[Constants STATUS_CODE]];
    [self rejectSelect:resolve writeableResp:[[NSMutableDictionary alloc] init] requestAddress:request.url];
    return;
  }
  
  NSString * targetPath = [request generateTargetFilePath];
  NSFileManager * defaultManager = [NSFileManager defaultManager];
  BOOL isDir;
  BOOL exists = [defaultManager fileExistsAtPath:targetPath isDirectory:&isDir];
  
  if(!isDir && exists)
  {
    NSMutableDictionary * resp = [[NSMutableDictionary alloc] init];
    [resp setObject:[@"file://" stringByAppendingString:targetPath] forKey:[Constants URL]];
    [resp setObject:[[NSNumber alloc] initWithBool:TRUE] forKey:[Constants SUCCESS]];
    resolve(resp);
  }
  else
  {
    if(isDir)
    {
      NSMutableDictionary * resp = [[NSMutableDictionary alloc] init];
      [resp setObject:@"can not write a directory" forKey:[Constants MESSAGE]];
      [resp setObject:@(-1) forKey:[Constants STATUS_CODE]];
      [self rejectSelect:resolve writeableResp:resp requestAddress:request.url];
    }
    else
    {
      if(data == nil)
      {
        [operationQueue addOperationWithBlock:^{
          [request checkUrlAccessible:^(AccessibleResult * _Nonnull accessible) {
            if(!accessible.accessible)
            {
              NSMutableDictionary * resp = [[NSMutableDictionary alloc] init];
              [resp setObject:accessible.message forKey:[Constants MESSAGE]];
              [resp setObject:@(accessible.responseCode) forKey:[Constants STATUS_CODE]];
              [self rejectSelect:resolve writeableResp:resp requestAddress:request.url];
            }
            else
            {
              [self post:request];
              [self rejectSelect:resolve writeableResp:[[NSMutableDictionary alloc] init] requestAddress:request.url];
            }
          }];
        }];
      }
      else
      {
        [self post:request];
        [self rejectSelect:resolve writeableResp:[[NSMutableDictionary alloc] init] requestAddress:request.url];
      }
    }
  }
}

- (void)emitProgressEvent:(NSString *)url didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
{
  if(self)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self sendEventWithName:@"RNAsyncCacheProgress" body:@{
        [Constants URL]:url,
        [Constants TOTAL]:@(totalBytesWritten),
        [Constants CURRENT]:@(MAX(0, bytesWritten))
      }];
    });
  }
}

- (void)onPostedExecption:(NSException *)exception taskId:(NSString *)taskId
{
  [self unsignTask:taskId];
}

- (void)onPostedError:(NSError *)error taskId:(NSString *)taskId
{
  [self unsignTask:taskId];
}

- (void)emitPostedEvent:(nonnull NSString *)url targetPath:(nonnull NSString *)targetPath fileSize:(int64_t)totalBytes errorCode:(long)statusCode errorMessage:(NSString * _Nullable)message taskId:(nonnull NSString *)taskId {
  [self unsignTask:taskId];
  if(self)
  {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self sendEventWithName:@"RNAsyncCachePosted" body:@{
        [Constants PATH]:targetPath,
        [Constants STATUS_CODE]:@(statusCode),
        [Constants MESSAGE]:message?message:@"",
        [Constants SIZE]:@(totalBytes),
        [Constants URL]:url
      }];
    });
  }
}


@end
