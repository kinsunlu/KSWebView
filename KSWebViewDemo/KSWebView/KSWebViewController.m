//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSConstants.h"
#import "KSWebViewController.h"

@interface KSWebViewController () <WKNavigationDelegate> {
    BOOL _isTerminateWebView;
}

@end

@implementation KSWebViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self applicationWillEnterForeground];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView evaluateJavaScriptMethod:k_WebViewDidAppear completionHandler:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    KSWebView *webView = self.webView;
    [webView pausePlayingVideo];
    [webView evaluateJavaScriptMethod:k_WebViewDidDisappear completionHandler:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isTerminateWebView = NO;
    
    self.title = @"正在加载...";
    
    KSWebView *webView = [KSWebView safelyReleaseWebViewWithFrame:CGRectZero delegate:self];
    __weak typeof(self) weakSelf = self;
    [webView setWebViewTitleChangedCallback:^(NSString *title) {
        if (title.length) {
            weakSelf.title = title;
        }
    }];
    [self layoutWebView:webView];
    _webView = webView;
    
    KSWebViewScriptHandler *reflection = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(scriptHandlerReflection:)];
    webView.scriptHandlers = @{k_CallReflection:reflection};
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)layoutWebView:(KSWebView *)webView {
    UIView *view = self.view;
    webView.frame = view.bounds;
    [view addSubview:webView];
}

-(void)loadWebView{
    if (_url.length) {
        [_webView loadWebViewWithURL:_url params:_params];
    } else if (_filePath.length) {
        [_webView loadWebViewWithFilePath:_filePath];
    }
}

-(void)scriptHandlerReflection:(WKScriptMessage*)message {
    NSString *body = message.body;
    [KSWebViewReflectiveService webViewReflectiveServiceWithSelf:self body:body];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(KSWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
}

- (void)webView:(KSWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}

- (void)webView:(KSWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

}

- (void)webView:(KSWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"error=%@",error.localizedDescription);
    [webView resetProgressView];
}

- (void)webView:(KSWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(KSWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webViewWebContentProcessDidTerminate:(KSWebView *)webView{
    _isTerminateWebView = YES;
}

-(void)applicationWillEnterForeground{
    if (_isTerminateWebView) {
        _isTerminateWebView = NO;
        [self loadWebView];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

@end
