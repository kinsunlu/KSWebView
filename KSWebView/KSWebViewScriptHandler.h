//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KSWebViewScriptHandler : NSObject

@property (nonatomic, weak, readonly) id target;
@property (readonly) SEL action;

- (instancetype)initWithTarget:(id)target action:(SEL)action;

+ (instancetype)scriptHandlerWithTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
