//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KSWebView.h"

@interface KSWebViewController : UIViewController <WKNavigationDelegate> //更改为自己的基类最佳

@property (nonatomic, weak, readonly) KSWebView *webView;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSDictionary *params;

//初始化时调用布局KSWebView,默认全屏(self.view = webView)
-(KSWebView*)loadWebView;
//开始WebView请求，继承后手动调用
-(void)startWebViewRequest;

//页面加载失败之后调用//此方法中有实现需执行super方法
- (void)webView:(KSWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;

@end
