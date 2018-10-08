//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

/*
 * KSWebDataStorageModule为js与原生公用数据存储模块
 * 可自由互相监听,无缝对接,H5与原生都可以对某个数据进行监听,从而实现UI或数据上的更新
 */

#import <Foundation/Foundation.h>

@class KSWebViewScriptHandler;
@interface KSWebDataStorageModule : NSObject

//注册在KSWebView的回调句柄,不用手动设置,WebView初始化时已经注入了
@property (nonatomic, readonly, class) NSDictionary <NSString*,KSWebViewScriptHandler*>*scriptHandlers;

+(void)setKeyValueDictionary:(NSDictionary*)dictionary;
//将key为key的value设置为value
+(void)setValue:(NSString*)value forKey:(NSString*)key;
//获得key为key的value
+(NSString*)valueForKey:(NSString*)key;

//给keyPath添加一个监听者,并回调给callback这个block
+(void)addObserver:(id)observer callback:(void(^)(NSString *value, NSString *oldValue))callback forKeyPath:(NSString*)keyPath;
//在keyPath的监听者中移除一个
+(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath;
//移除所有为observer的监听
+(void)removeObserver:(id)observer;

@end
