#import "AccessibleResult.h"

@implementation AccessibleResult

- (instancetype)init:(NSInteger)responseCode responseErrorDescription:(NSString *)message contentType:(NSString *)contentType urlAccessible:(BOOL)accessible
{
  self = [super init];
  self.accessible = accessible;
  self.message = message;
  self.responseCode = responseCode;
  self.contentType = contentType;
  return self;
}

@end
