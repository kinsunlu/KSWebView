//
//  KSOCObjectTools.h
//  KSWebViewDemo
//
//  Created by kinsun on 2018/8/27.
//  Copyright © 2018年 kinsun. All rights reserved.
//
//当有了KSOCObjectTools之后可以使用更直观的KSOCObjectTools以js的方式编写代码并执行OC代码，详细介绍见readme.md

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN size_t __ks_lengthFromType(const char *type);
FOUNDATION_EXTERN NSNumber *_Nullable __ks_numberFromInvocation(NSInvocation *invocation, size_t length, const char *type);

@class KSWebViewScriptHandler;
@interface KSOCObjectTools : NSObject

@property (nonatomic, readonly, copy, class) NSString *initJavaScriptString;
@property (nonatomic, readonly, class) NSDictionary <NSString*, KSWebViewScriptHandler*>*scriptHandlers;

@end

NS_ASSUME_NONNULL_END
