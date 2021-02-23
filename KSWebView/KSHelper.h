//
//  KSHelper.h
//  KSWebViewDemo
//
//  Created by Kinsun on 2021/2/22.
//  Copyright © 2021 kinsun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KSHelper : NSObject

+ (NSString *_Nullable)errorJsonWithError:(NSError *)error;

+ (NSString *_Nullable)errorJsonWithCode:(NSInteger)code msg:(NSString *)msg;

+ (NSString *_Nullable)jsonWithObject:(id)object;

+ (NSString *)jsParams:(id)params;

@end

NS_ASSUME_NONNULL_END
