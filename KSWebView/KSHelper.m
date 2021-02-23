//
//  KSHelper.m
//  KSWebViewDemo
//
//  Created by Kinsun on 2021/2/22.
//  Copyright © 2021 kinsun. All rights reserved.
//

#import "KSHelper.h"

@implementation KSHelper

+ (NSString *)errorJsonWithError:(NSError *)error {
    return [self errorJsonWithCode:error.code msg:error.localizedDescription];
}

+ (NSString *)errorJsonWithCode:(NSInteger)code msg:(NSString *)msg {
    return [self jsonWithObject:@{@"code": @(code), @"msg": msg ?: @""}];
}

+ (NSString *)jsonWithObject:(id)object {
    if (object == nil) return nil;
    if ([object isKindOfClass:NSString.class]) {
        return [NSString stringWithFormat:@"\"%@\"", object];
    }
    if ([object isKindOfClass:NSNumber.class]) {
        return [NSString stringWithFormat:@"%@", object];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (data == nil) return nil;
    return [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)jsParams:(id)params {
    if (params == NSNull.null) {
        return @"null";
    }
    if ([params isKindOfClass:NSNumber.class]) {
        return [NSString stringWithFormat:@"%@", params];
    }
    if ([params isKindOfClass:NSString.class]) {
        return [NSString stringWithFormat:@"'%@'", params];
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    if (data == nil) return nil;
    return [NSString.alloc initWithData:data encoding:NSUTF8StringEncoding];
}

@end
