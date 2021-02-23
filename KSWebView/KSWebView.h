//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "KSWebViewScriptHandler.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const k_BlankPage;
FOUNDATION_EXPORT NSString * const k_WebViewDidAppear;
FOUNDATION_EXPORT NSString * const k_WebViewDidDisappear;

@interface KSWebView : WKWebView

@property (nonatomic, copy, nullable, readonly) NSDictionary <NSString *, KSWebViewScriptHandler *> *scriptHandlers;

@property (nonatomic, weak, readonly) UIView *webContentView;
@property (nonatomic, copy, nullable) void (^webViewTitleChangedCallback)(NSString * _Nullable title);

/// webview加载前时的HTTPHeaders loadrequest之前设置
@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *HTTPHeaders;

/// 进度条
@property (nonatomic, weak, readonly) CALayer *progressLayer;

- (instancetype)initWithScriptHandlers:(NSDictionary <NSString *, KSWebViewScriptHandler *> *_Nullable)scriptHandlers;

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration scriptHandlers:(NSDictionary <NSString *, KSWebViewScriptHandler *> *_Nullable)scriptHandlers;

/// 重置进度条
- (void)resetProgressLayer;

/// 加载远程网页
/// @param url 链接地址
/// @param params 参数键值对，设置之后会自动在连接后面拼接参数
- (void)loadWebViewWithURL:(NSString *)url params:(NSDictionary <NSString *, id> *_Nullable)params;

/// 加载本地网页
/// @param filePath 本地文件所在路径
- (void)loadWebViewWithFilePath:(NSString *)filePath;

- (WKNavigation *)loadRequest:(NSMutableURLRequest *)request;


/// 由于WKWebView用默认方法不能截图所以就有了这两个方法,
/// 原理就是我会生成一个imageview加在webview上等调用系统截图方法后再移除.
/// 截图前调用一下
- (void)webViewBeginScreenshot;

/// 截图后调用一下
- (void)webViewEndScreenshot;


/// 获取网页中的视频数量
/// @param callback 控制回调
- (void)videoPlayerCount:(void(^)(NSInteger))callback;

/// 获取网页中的视频播放总时长
/// @param index 第几个视频
/// @param callback 控制回调
- (void)videoDurationWithIndex:(NSInteger)index callback:(void(^)(double))callback;

/// 获取网页中的视频已播放时长
/// @param index 第几个视频
/// @param callback 控制回调
- (void)videoCurrentTimeWithIndex:(NSInteger)index callback:(void(^)(double))callback;

/// 使网页中的视频进入播放状态
/// @param index 第几个视频
- (void)playVideoWithIndex:(NSInteger)index;

/// 暂停正在播放的视频
- (void)pausePlayingVideo;

@end

NS_ASSUME_NONNULL_END
