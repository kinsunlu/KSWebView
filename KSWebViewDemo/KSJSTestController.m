//
//  KSJSTestController.m
//  KSWebViewDemo
//
//  Created by kinsun on 2018/8/29.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebViewController.h"

@interface KSJSTestController : KSWebViewController

@end

@implementation KSJSTestController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startWebViewRequest];
}

-(KSWebView *)loadWebView {
    KSWebView *webView = [[KSWebView alloc] initWithFrame:self.view.frame delegate:self];
    self.view = webView;
    UIScrollView *scrollView = webView.scrollView;
    CGFloat top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    scrollView.contentInset = (UIEdgeInsets){top,0.f,0.f,0.f};//复杂的Html中不建议设置此项会影响布局
    return webView;
}

@end
