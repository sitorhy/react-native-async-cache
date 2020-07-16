#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccessibleResult : NSObject

@property(nonatomic) NSInteger responseCode;

@property(nonatomic) BOOL accessible;

@property(nonatomic) NSString * message;

@property(nonatomic) NSInteger size;

@property(nonatomic) NSString * contentType;

-(instancetype)init:(NSInteger)responseCode responseErrorDescription:(NSString *)message contentType:(NSString *)contentType urlAccessible:(BOOL)accessible;

@end

NS_ASSUME_NONNULL_END
