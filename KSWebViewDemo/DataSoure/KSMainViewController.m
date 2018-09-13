//
//  KSMainViewController.m
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSMainViewController.h"
#import "KSWebDataStorageModule.h"

@implementation KSMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KSWebViewScriptHandler *testJSCallback  = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerTestJSCallbackWithMessage:)];
    KSWebViewScriptHandler *testReturnValue = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerTestReturnValue)];
    KSWebViewScriptHandler *alert           = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerAlertWithMessage:)];
    KSWebViewScriptHandler *openNewPage     = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerOpenNewPage)];
    self.webView.scriptHandlers = @{@"testJSCallback" :testJSCallback,
                                    @"testReturnValue":testReturnValue,
                                    @"alert"          :alert,
                                    @"openNewPage"    :openNewPage};
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    self.filePath = path;
    [self loadWebView];
}

-(void)layoutWebView:(KSWebView *)webView {
    [super layoutWebView:webView];
    UIScrollView *scrollView = webView.scrollView;
    CGFloat top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    scrollView.contentInset = (UIEdgeInsets){top,0.f,0.f,0.f};//复杂的Html中不建议设置此项会影响布局
}

-(void)webViewScriptHandlerTestJSCallbackWithMessage:(WKScriptMessage*)message {
    NSLog(@"JS调用了客户端的方法!");
}

//return的值 务必转成String
-(NSString*)webViewScriptHandlerTestReturnValue {
    return @"拿到客户端反回的值啦!!";
}

-(void)webViewScriptHandlerAlertWithMessage:(WKScriptMessage*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"来自网页的信息" message:message.body preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)webViewScriptHandlerOpenNewPage {
    KSMainViewController *controller = [[KSMainViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
