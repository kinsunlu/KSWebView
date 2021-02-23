//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KSWebDataStorageModule : NSMutableDictionary <NSString *, id <NSCopying>>

/// 使用该单利可以访问与webview互通的存储空间。
@property (nonatomic, readonly, class) KSWebDataStorageModule *sharedModule;

@end

NS_ASSUME_NONNULL_END
