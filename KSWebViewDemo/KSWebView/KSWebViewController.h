//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSWebView.h"

@interface KSWebViewController : UIViewController //更改为自己的基类最佳

@property (nonatomic, weak, readonly) KSWebView *webView;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSDictionary *params;

-(void)loadWebView;//继承后手动调用
//初始化时调用布局继承后可不用调用super layoutWebview: 方法,默认全屏
-(void)layoutWebView:(KSWebView *)webView;

//页面开始加载时调用
- (void)webView:(KSWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;
//当内容开始返回时调用
- (void)webView:(KSWebView *)webView didCommitNavigation:(WKNavigation *)navigation;
//页面加载完成之后调用
- (void)webView:(KSWebView *)webView didFinishNavigation:(WKNavigation *)navigation;
//页面加载失败之后调用
- (void)webView:(KSWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;
//这个代理方法表示当客户端收到服务器的响应头，根据response相关信息，可以决定这次跳转是否可以继续进行
- (void)webView:(KSWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

@end
