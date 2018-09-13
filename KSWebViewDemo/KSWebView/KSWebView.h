//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "KSWebViewScriptHandler.h"

FOUNDATION_EXPORT NSString * const k_BlankPage;
FOUNDATION_EXPORT NSString * const k_WebViewDidAppear;
FOUNDATION_EXPORT NSString * const k_WebViewDidDisappear;
FOUNDATION_EXPORT NSString * const k_CallJsMethod;

@interface KSWebView : WKWebView

/*
 * webview的JS调用原生的回调字典Key为被H5调用的方法名
 * loadrequest之前设置
 */
@property (nonatomic, strong) NSDictionary <NSString*,KSWebViewScriptHandler*>*scriptHandlers;
/*
 * webview加载前需要注入的css或者html信息
 * loadrequest之前设置
 */
@property (nonatomic, strong) NSArray <NSString*>*htmlElementArray;
/*
 * webview加载前时的HTTPHeaders
 * loadrequest之前设置
 */
@property (nonatomic, strong) NSDictionary <NSString*,NSString*>*HTTPHeaders;

@property (nonatomic, weak, readonly) UIView *progressView;
@property (nonatomic, weak, readonly) UIView *webContentView;
@property (nonatomic, copy) void (^webViewTitleChangedCallback)(NSString *title);

//此方法解释见KSWebViewMemoryManager.h
+(instancetype)safelyReleaseWebViewWithFrame:(CGRect)frame delegate:(id<WKNavigationDelegate>)delegate;
-(instancetype)initWithFrame:(CGRect)frame delegate:(id<WKNavigationDelegate>)delegate;

// @params 设置之后会自动在连接后面拼接参数
-(void)loadWebViewWithURL:(NSString*)url params:(NSDictionary*)params;
-(void)loadWebViewWithFilePath:(NSString *)filePath;

-(WKNavigation *)loadRequest:(NSMutableURLRequest *)request;

-(void)resetProgressView;

/*
 * @methodName H5定义的方法名 //更改宏定义k_CallJsMethod 即可更改统一的方法名
 * 有多个参数就生成为 @"methodName','arg1','arg2" 这样的string设置给methodName(因为方法内部已经有两个单引号了所以前面和后面没有...)
 * 该方法是为了H5方便,调用该方法会统一调用一个H5方法,然后通过参数(methodName)让H5方便统计一些信息.
 * 默认H5返回没有的方法的错误码为-999 ,如果调用了H5不存在的方法请H5主动返回-999就可以了.
 * 当然如果你不想使用也完全没有问题,这完全取决于你
 */
-(void)evaluateJavaScriptMethod:(NSString*)methodName completionHandler:(void (^)(id returnValue, NSError *error))completionHandler;

/*
 *由于WKWebView用默认方法不能截图所以就有了这两个方法,原理就是我会生成一个imageview加在webview上等调用系统截图方法后再移除.
 */
-(void)webViewBeginScreenshot;//截图前调用一下
-(void)webViewEndScreenshot;//截图后调用一下

/*
 * 视频相关
 * 控制webview中的视频标签
 */
-(void)videoPlayerCount:(void(^)(NSUInteger))callback;
-(void)videoDurationWithIndex:(NSUInteger)index callback:(void(^)(double))callback;
-(void)videoCurrentTimeWithIndex:(NSUInteger)index callback:(void(^)(double))callback;
-(void)playVideoWithIndex:(NSUInteger)index;
-(void)pausePlayingVideo;

@end
