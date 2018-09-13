//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebView.h"

@interface WKScriptMessage ()

-(instancetype)_initWithBody:(id)body webView:(KSWebView*)webView frameInfo:(WKFrameInfo*)frame name:(NSString*)name;

@end

#import "KSWebDataStorageModule.h"
#import "KSWebViewMemoryManager.h"
#import "KSOCObjectTools.h"
#import "KSConstants.h"

NSString * const k_EstimatedProgress        = @"estimatedProgress";
NSString * const k_WebViewTitle             = @"title";
NSString * const k_GetVideoTag              = @"document.getElementsByTagName('video')";
NSString * const k_WebViewBridgeIndexKey    = @"__ks_web_bridge_";
NSString * const k_INIT_SCRIPT              = @"__ks_bridge_index = '%@';function __getKsJsBridge(){return{call:function(b,a){return prompt(window.__ks_bridge_index+b,a)}}}window.control=__getKsJsBridge()";

NSString * const k_BlankPage                = @"about:blank";
NSString * const k_WebViewDidAppear         = @"viewDidAppearOnApp";
NSString * const k_WebViewDidDisappear      = @"viewDidDisappearOnApp";
NSString * const k_CallJsMethod             = @"javascript:callJsMethod('%@')";

@interface KSWebView () <WKUIDelegate> {
    __weak UIImageView *_screenshotView;
    __weak id<WKUIDelegate> _UIDelegate;
}

@property (nonatomic, class, readonly) NSArray<WKUserScript*>*initUserScripts;

@end

@implementation KSWebView

+(instancetype)safelyReleaseWebViewWithFrame:(CGRect)frame delegate:(id<WKNavigationDelegate>)delegate {
    KSWebView *webView = [[self alloc]initWithFrame:frame delegate:delegate];
    [KSWebViewMemoryManager addWebView:webView];
    return webView;
}

-(instancetype)initWithFrame:(CGRect)frame delegate:(id<WKNavigationDelegate>)delegate {
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    for (WKUserScript *script in KSWebView.initUserScripts)
        [userContentController addUserScript:script];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = NO;
    configuration.userContentController = userContentController;
    
    if (self = [super initWithFrame:frame configuration:configuration]) {
        self.navigationDelegate = delegate;
        super.UIDelegate = self;
        UIScrollView *scrollView = self.scrollView;
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        scrollView.contentInset = UIEdgeInsetsZero;
        if (k_IOS_Version >= 11.f) {
#pragma clang diagnostic ignored"-Wunguarded-availability-new"
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        Class class = NSClassFromString(@"WKContentView");
        for (UIView *view in scrollView.subviews) {
            if ([view isKindOfClass:class]) {
                _webContentView = view;
            }
        }
        
        UIView *progressView = [[UIView alloc]init];
        progressView.backgroundColor = [UIColor blueColor];
        [self addSubview:progressView];
        _progressView = progressView;
        
        NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
        [self addObserver:self forKeyPath:k_EstimatedProgress options:options context:NULL];
        [self addObserver:self forKeyPath:k_WebViewTitle options:options context:NULL];
        
        NSMutableDictionary *scriptHandlers = [NSMutableDictionary dictionaryWithDictionary:KSOCObjectTools.scriptHandlers];
        [scriptHandlers addEntriesFromDictionary:KSWebDataStorageModule.scriptHandlers];
        self.scriptHandlers = scriptHandlers;
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGFloat windowWidth = self.frame.size.width;
    k_creatFrameElement;
    viewW=_progressView.frame.size.width;
    viewH=windowWidth*0.008f;
    viewY=self.scrollView.contentInset.top;
    k_settingFrame(_progressView);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) {
        if (keyPath == k_EstimatedProgress) {
            NSString *url = self.URL.absoluteString;
            if (![url isEqualToString:k_BlankPage]) {
                double estimatedProgress = self.estimatedProgress;
                CGRect frame = _progressView.frame;
                frame.size.width = self.frame.size.width*estimatedProgress;
                __weak typeof(self) weakSelf = self;
                [UIView animateWithDuration:0.2f animations:^{
                    _progressView.frame = frame;
                } completion:^(BOOL finished) {
                    if (estimatedProgress >= 1.f) {
                        [weakSelf resetProgressView];
                    } else {
                        _progressView.hidden = NO;
                    }
                }];
            }
        } else if (_webViewTitleChangedCallback && keyPath == k_WebViewTitle) {
            _webViewTitleChangedCallback(self.title);
        }
    }
}

-(void)resetProgressView {
    _progressView.hidden = YES;
    CGRect frame = _progressView.frame;
    frame.size.width = 0.f;
    _progressView.frame = frame;
}

-(void)setScriptHandlers:(NSDictionary<NSString *,KSWebViewScriptHandler*> *)scriptHandlers {
    NSArray <NSString*>*allKeys = scriptHandlers.allKeys;
    if (allKeys.count) {
        if (_scriptHandlers) {
            NSMutableDictionary <NSString*,KSWebViewScriptHandler*>*tempScriptHandlers = [NSMutableDictionary dictionaryWithDictionary:_scriptHandlers];
            [tempScriptHandlers addEntriesFromDictionary:scriptHandlers];
            _scriptHandlers = tempScriptHandlers;
        } else {
            _scriptHandlers = scriptHandlers;
        }
    }
}

-(void)setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    _UIDelegate = UIDelegate;
}

-(id<WKUIDelegate>)UIDelegate {
    return _UIDelegate;
}

-(void)webView:(KSWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)body initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler {
    NSString *prefix = k_WebViewBridgeIndexKey;
    if ([prompt hasPrefix:prefix]) {
        id returnValue = nil;
        NSString *name = [prompt substringFromIndex:prefix.length];
        KSWebViewScriptHandler *handler = [_scriptHandlers objectForKey:name];
        id target = handler.target;
        SEL action = handler.action;
        if (target && action) {
            NSMethodSignature *signature = [target methodSignatureForSelector:action];
            const char *returnType = signature.methodReturnType;
            BOOL notHasReturnValue = !strcmp(returnType, @encode(void));
            if (notHasReturnValue) completionHandler(nil);
            if ([target respondsToSelector:action]) {
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                if (signature.numberOfArguments > 2) {
                    WKScriptMessage *message = [[WKScriptMessage alloc] _initWithBody:body webView:webView frameInfo:frame name:name];
                    if (notHasReturnValue) {
                        [target performSelector:action withObject:message];
                    } else {
                        returnValue = [target performSelector:action withObject:message];
                    }
                } else {
                    if (notHasReturnValue) {
                        [target performSelector:action];
                    } else {
                        returnValue = [target performSelector:action];
                    }
                }
            }
            if (notHasReturnValue) return;
        } else returnValue = @"-999";
        completionHandler(returnValue);
    } else if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        [_UIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:body initiatedByFrame:frame completionHandler:completionHandler];
    }
}

-(void)evaluateJavaScriptMethod:(NSString*)methodName completionHandler:(void (^)(id returnValue, NSError *error))completionHandler {
    if (methodName) {
        NSString *javaScript = [NSString stringWithFormat:k_CallJsMethod, methodName];
        [self evaluateJavaScript:javaScript completionHandler:^(id obj, NSError * _Nullable error) {
            if (completionHandler) {
                BOOL hasMethod = obj != nil;
                if ([obj isKindOfClass:NSNumber.class]) {
                    hasMethod = [obj integerValue] != -999;
                }
                if (hasMethod) {
                    completionHandler(obj, error);
                } else {
                    if (!error) {
                        error = [NSError errorWithDomain:@"KSJavaScriptErrorDomain" code:-999 userInfo:@{NSLocalizedDescriptionKey:@"没有找到JavaScript方法",
                                                                                                       NSLocalizedFailureReasonErrorKey:@"HTML中不包含此方法"}];
                    }
                    completionHandler(nil, error);
                }
            }
        }];
    }
}

-(void)setHtmlElementArray:(NSArray<NSString *> *)elementArray {
    _htmlElementArray = elementArray;
    if (elementArray.count) {
        NSMutableString *elementString = [NSMutableString string];
        for (NSString *css in elementArray) {
            [elementString appendString:css];
        }
        if (elementString.length) {
            NSString *javascript = [KSWebView createElementWithJavaScript:elementString];
            WKUserScript *script = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
            [self.configuration.userContentController addUserScript:script];
        }
    }
}

-(WKNavigation *)loadRequest:(NSMutableURLRequest *)request {
    //可以在此处添加请求共有自定义的Header信息
    
    if (_HTTPHeaders) {
        NSArray <NSString*>*allKeys = _HTTPHeaders.allKeys;
        for (NSString *key in allKeys) {
            NSString *value = [_HTTPHeaders objectForKey:key];
            if (value) {
                [request addValue:value forHTTPHeaderField:key];
            }
        }
    }
    return [super loadRequest:request];
}

-(void)loadWebViewWithURL:(NSString*)url params:(NSDictionary*)params {
    if (url.length) {
        NSMutableString *urlString = [NSMutableString stringWithString:url];
        if (params) {
            NSString *bridge = @"?";
            if ([urlString rangeOfString:bridge].location != NSNotFound) {
                bridge = @"&";
            }
            NSMutableString *paramsStr = [NSMutableString stringWithString:bridge];
            NSArray *allKeys = params.allKeys;
            for (int i=0; i<allKeys.count; i++) {
                NSString *key = [allKeys objectAtIndex:i];
                NSString *value = [[params objectForKey:key] description];
                [paramsStr appendFormat:@"%@=%@",key,value];
                if (i != allKeys.count-1) {
                    [paramsStr appendString:@"&"];
                }
            }
            [urlString appendString:paramsStr];
        }
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [self loadRequest:request];
    }
}

-(void)loadWebViewWithFilePath:(NSString *)filePath {
    if (filePath.length) {
        NSString *questionMark = @"?";
        NSArray <NSString*>*stringArray = [filePath componentsSeparatedByString:questionMark];
        NSURL *fileURL = nil;
        if (stringArray.count > 1) {
            fileURL = [NSURL fileURLWithPath:stringArray.firstObject];
        } else {
            fileURL = [NSURL fileURLWithPath:filePath];
        }
        if (k_IOS_Version >= 9.f) {
            NSURL *baseURL = fileURL;
            if (stringArray.count > 1) {
                NSString *fileURLString = [NSString stringWithFormat:@"%@%@%@",fileURL.absoluteString,questionMark,stringArray.lastObject];
                baseURL = [NSURL URLWithString:fileURLString];
            }
#pragma clang diagnostic ignored"-Wunguarded-availability"
            [self loadFileURL:baseURL allowingReadAccessToURL:baseURL];
        } else {
            NSString *path = fileURL.path;
            NSError *error = nil;
            if (fileURL.isFileURL && [fileURL checkResourceIsReachableAndReturnError:&error]) {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSString *indexHTMLName = path.lastPathComponent;
                NSString *rootPath = [path stringByReplacingOccurrencesOfString:indexHTMLName withString:@""];
                NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:rootPath.lastPathComponent];
                if ([fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                    [self copyItemsAtFromRootPath:rootPath toRootPath:temDirURL.path];
                }
                NSURL *dstURL = [temDirURL URLByAppendingPathComponent:indexHTMLName];
                NSURL *baseURL = dstURL;
                if (stringArray.count > 1) {
                    NSString *fileURLString = [NSString stringWithFormat:@"%@%@%@",dstURL.absoluteString,questionMark,stringArray.lastObject];
                    baseURL = [NSURL URLWithString:fileURLString];
                }
                NSLog(@"baseURL=%@",baseURL);
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
                [self loadRequest:request];
            }
        }
    }
}

-(void)copyItemsAtFromRootPath:(NSString*)fromRootPath toRootPath:(NSString*)toRootPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *filePaths = [fileManager contentsOfDirectoryAtPath:fromRootPath error:&error];
    if (!error) {
        for (NSString *name in filePaths) {
            NSString *fromPath = [fromRootPath stringByAppendingPathComponent:name];
            NSString *toPath = [toRootPath stringByAppendingPathComponent:name];
            BOOL isDir = NO;
            [fileManager fileExistsAtPath:fromPath isDirectory:&isDir];
            if (isDir) {//是文件夹
                if ([fileManager createDirectoryAtPath:toPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                    [self copyItemsAtFromRootPath:fromPath toRootPath:toPath];
                }
            } else {
                [fileManager copyItemAtPath:fromPath toPath:toPath error:&error];
            }
        }
    }
}

-(void)webViewBeginScreenshot {
    CALayer *layer = self.layer;
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!_screenshotView) {
        UIImageView *screenshotView = [[UIImageView alloc]init];
        screenshotView.backgroundColor = [UIColor whiteColor];
        [self addSubview:screenshotView];
        _screenshotView = screenshotView;
    }
    _screenshotView.image = img;
    _screenshotView.frame = self.bounds;
    _screenshotView.hidden = NO;
}

-(void)webViewEndScreenshot {
    if (_screenshotView) {
        _screenshotView.hidden = YES;
    }
}

-(void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil) {
        self.scrollView.delegate = nil;
    }
    [super willMoveToSuperview:newSuperview];
}

+(NSArray<WKUserScript *> *)initUserScripts {
    static NSArray<WKUserScript *> *k_initUserScripts = nil;
    if (k_initUserScripts == nil) {
        NSString *noSelectCss = [self createElementWithJavaScript:@"-webkit-touch-callout:none;"];
        WKUserScript *noneSelectScript = [[WKUserScript alloc] initWithSource:noSelectCss injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        NSString *scriptEntrance = [NSString stringWithFormat:k_INIT_SCRIPT, k_WebViewBridgeIndexKey];
        WKUserScript *initScript = [[WKUserScript alloc] initWithSource:scriptEntrance injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        
        NSString *oc_object_tools = KSOCObjectTools.initJavaScriptString;
        WKUserScript *toolsScript = [[WKUserScript alloc] initWithSource:oc_object_tools injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        k_initUserScripts = @[noneSelectScript, initScript, toolsScript];
    }
    return k_initUserScripts;
}

+(NSString*)createElementWithJavaScript:(NSString*)code {
    NSString *javascript = [NSString stringWithFormat:@"var style = document.createElement('style');style.type = 'text/css';var cssContent = document.createTextNode('body{%@}');style.appendChild(cssContent);document.body.appendChild(style);", code];
    return javascript;
}

-(void)dealloc {
    self.navigationDelegate = nil;
    super.UIDelegate = nil;
    [KSWebDataStorageModule removeObserver:self];
    [self removeObserver:self forKeyPath:k_EstimatedProgress];
    [self removeObserver:self forKeyPath:k_WebViewTitle];
    NSLog(@"webView dealloc");
}

-(void)videoPlayerCount:(void(^)(NSUInteger))callback {
    if (callback) {
        NSString * hasVideoTestString = [NSString stringWithFormat:@"%@.length",k_GetVideoTag];
        [self evaluateJavaScript:hasVideoTestString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
            if (callback) callback(result.unsignedIntegerValue);
        }];
    }
}

-(void)videoDurationWithIndex:(NSUInteger)index callback:(void(^)(double))callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        [self videoPlayerCount:^(NSUInteger count) {
            if (index < count) {
                NSString * durationString = [NSString stringWithFormat:@"%@[%td].duration.toFixed(1)", k_GetVideoTag, index];
                [weakSelf evaluateJavaScript:durationString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
                    if (callback) callback(result.doubleValue);
                }];
            }
        }];
    }
}

-(void)videoCurrentTimeWithIndex:(NSUInteger)index callback:(void(^)(double))callback {
    if (callback) {
        __weak typeof(self) weakSelf = self;
        [self videoPlayerCount:^(NSUInteger count) {
            if (index < count) {
                NSString * durationString = [NSString stringWithFormat:@"%@[%td].currentTime.toFixed(1)", k_GetVideoTag, index];
                [weakSelf evaluateJavaScript:durationString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
                    if (callback) callback(result.doubleValue);
                }];
            }
        }];
    }
}

-(void)playVideoWithIndex:(NSUInteger)index {
    __weak typeof(self) weakSelf = self;
    [self videoPlayerCount:^(NSUInteger count) {
        if (index < count) {
            NSString *playString = [NSString stringWithFormat:@"%@[%td].play()", k_GetVideoTag, index];
            [weakSelf evaluateJavaScript:playString completionHandler:nil];
        }
    }];
}

-(void)pausePlayingVideo {
    __weak typeof(self) weakSelf = self;
    [self videoPlayerCount:^(NSUInteger count) {
        if (count > 0) {
            NSString *pauseString = [NSString stringWithFormat:@"var dom = %@;for(var i = 0; i < dom.length; i++){dom[i].pause();}", k_GetVideoTag];
            [weakSelf evaluateJavaScript:pauseString completionHandler:nil];
        }
    }];
}

#pragma mark - WKUIDelegate

-(KSWebView *)webView:(KSWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    KSWebView *value = nil;
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        value = (KSWebView*)[_UIDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return value;
}

-(void)webViewDidClose:(KSWebView *)webView {
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        [_UIDelegate webViewDidClose:webView];
    }
}

-(void)webView:(KSWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        [_UIDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

-(void)webView:(KSWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        [_UIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

-(BOOL)webView:(KSWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    BOOL result = NO;
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        result = [_UIDelegate webView:webView shouldPreviewElement:elementInfo];
    }
    return result;
}

-(UIViewController *)webView:(KSWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions {
    UIViewController *controller = nil;
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        controller = [_UIDelegate webView:webView previewingViewControllerForElement:elementInfo defaultActions:previewActions];
    }
    return controller;
}

-(void)webView:(KSWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    if (_UIDelegate && [_UIDelegate respondsToSelector:_cmd]) {
        [_UIDelegate webView:webView commitPreviewingViewController:previewingViewController];
    }
}

@end
