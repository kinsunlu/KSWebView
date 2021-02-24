//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebViewController.h"

@implementation KSWebViewController {
    BOOL _isTerminateWebView;
}
@dynamic view;

- (void)loadView {
    [super loadView];
    _isTerminateWebView = NO;
    KSWebView *webView = [self loadWebView];
    __weak typeof(self) weakSelf = self;
    [webView setWebViewTitleChangedCallback:^(NSString *title) {
        if (title.length != 0) {
            weakSelf.title = title;
        }
    }];
    self.view = webView;
}

- (KSWebView *)loadWebView {
    return [KSWebView.alloc initWithScriptHandlers:self.loadScriptHandlers];
}

- (NSDictionary <NSString *, KSWebViewScriptHandler *> *)loadScriptHandlers {
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"正在加载...";
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applicationWillEnterForeground];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view evaluateJavaScript:_ks_WebViewDidAppear completionHandler:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    KSWebView *webView = self.view;
    [webView pausePlayingVideo];
    [webView evaluateJavaScript:_ks_WebViewDidDisappear completionHandler:nil];
}

- (void)startWebViewRequest {
    if (_url.length != 0) {
        [self.view loadWebViewWithURL:_url params:_params];
    } else if (_filePath.length != 0) {
        [self.view loadWebViewWithFilePath:_filePath];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(KSWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"error=%@",error.localizedDescription);
    [webView resetProgressLayer];
}

- (void)webViewWebContentProcessDidTerminate:(KSWebView *)webView {
    _isTerminateWebView = YES;
}

- (void)applicationWillEnterForeground {
    if (_isTerminateWebView) {
        _isTerminateWebView = NO;
        [self loadWebView];
    }
}

- (void)dealloc {
    if (self.viewIfLoaded) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    }
}

@end
