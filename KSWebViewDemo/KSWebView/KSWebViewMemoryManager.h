//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

/* 由于WKWebview内核原因,在某些请求或JS在执行时我们关闭了页面在ARC环境下导致webview被释放
 * 为了避免这类情况发生所以一般建议创建webview时使用这个内存管理类,将延缓webview释放,以避免
 * 调用被释放的对象
 */

#import <Foundation/Foundation.h>

@class KSWebView;
@interface KSWebViewMemoryManager : NSObject

+(void)addWebView:(KSWebView*)webView;

@end
