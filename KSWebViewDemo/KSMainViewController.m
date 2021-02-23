//
//  KSMainViewController.m
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSMainViewController.h"
#import "KSWebDataStorageModule.h"

@interface KSMainViewController () <WKUIDelegate>

@end

@implementation KSMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    self.filePath = path;
    [self startWebViewRequest];
}

- (KSWebView *)loadWebView {
    KSWebView *webView = [super loadWebView];
    webView.UIDelegate = self;
    return webView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIScrollView *scrollView = self.view.scrollView;
    CGFloat top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    scrollView.contentInset = (UIEdgeInsets){top, 0.0, 0.0, 0.0};//复杂的Html中不建议设置此项会影响布局
}

- (NSDictionary<NSString *,KSWebViewScriptHandler *> *)loadScriptHandlers {
    KSWebViewScriptHandler *testJSCallback  = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerTestJSCallback)];
    KSWebViewScriptHandler *testReturnValue = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerTestReturnValue)];
    KSWebViewScriptHandler *alert           = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerAlertWithMessage:)];
    KSWebViewScriptHandler *openNewPage     = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerOpenNewPage)];
    return @{@"testJSCallback" :testJSCallback,
             @"testReturnValue":testReturnValue,
             @"alert"          :alert,
             @"openNewPage"    :openNewPage};
}

- (void)webViewScriptHandlerTestJSCallback {
    NSLog(@"JS调用了客户端的方法!");
}

/// 可以return任意基本数据类型 或 NSString NSNumber NSArray NSDictionary
- (int)webViewScriptHandlerTestReturnValue {
    return 100;
}

- (void)webViewScriptHandlerAlertWithMessage:(int)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"来自网页的信息" message:[NSString stringWithFormat:@"客户端返回的值为%d", message] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webViewScriptHandlerOpenNewPage {
    KSMainViewController *controller = [[KSMainViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    completionHandler(@"test");
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"来自网页的信息" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completionHandler();
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    completionHandler(YES);
}

@end
