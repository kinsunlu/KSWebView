//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebView.h"

@interface KSWebView ()

- (void)_runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)body initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler;

@end

static NSString * const __ks__WebViewBridgeIndexKey = @"__ks_web_bridge_";

@interface __KSWebViewUIDelegatePuppet : NSObject <WKUIDelegate>

@property (nonatomic, weak) id<WKUIDelegate> delegate;

@end

@implementation __KSWebViewUIDelegatePuppet

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)) {
        return YES;
    }
    if (_delegate == nil) {
        return [super respondsToSelector:aSelector];
    }
    return [_delegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _delegate;
}

- (void)webView:(KSWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)body initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler {
    NSString *prefix = __ks__WebViewBridgeIndexKey;
    if ([prompt hasPrefix:prefix]) {
        [webView _runJavaScriptTextInputPanelWithPrompt:[prompt substringFromIndex:prefix.length] defaultText:body initiatedByFrame:frame completionHandler:completionHandler];
    } else if (_delegate != nil && [_delegate respondsToSelector:_cmd]) {
        [_delegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:body initiatedByFrame:frame completionHandler:completionHandler];
    } else completionHandler(nil);
}

@end

#import "KSWebDataStorageModule.h"
#import "KSOCObjectTools.h"
#import "KSHelper.h"

static NSString * const __ks__EstimatedProgress = @"estimatedProgress";
static NSString * const __ks__WebViewTitle      = @"title";
static NSString * const __ks__GetVideoTag       = @"document.getElementsByTagName('video')";

NSString * const _ks_BlankPage              = @"about:blank";
NSString * const _ks_WebViewDidAppear       = @"viewDidAppearOnApp()";
NSString * const _ks_WebViewDidDisappear    = @"viewDidDisappearOnApp()";

static NSString * const __ks__questionMark  = @"?";
static NSString * const __ks__andMark       = @"&";

@implementation KSWebView {
    __weak UIImageView *_screenshotView;
    __KSWebViewUIDelegatePuppet *_puppet;
    NSMapTable <NSString *, NSString *>*_jsObserveMap;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    return [self initWithFrame:frame configuration:configuration scriptHandlers:nil];
}

- (instancetype)initWithScriptHandlers:(NSDictionary<NSString *,KSWebViewScriptHandler *> *)scriptHandlers {
    return [self initWithFrame:CGRectZero configuration:WKWebViewConfiguration.alloc.init scriptHandlers:scriptHandlers];
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration scriptHandlers:(NSDictionary <NSString *, KSWebViewScriptHandler *> *)scriptHandlers {
    if (self = [super initWithFrame:frame configuration:configuration]) {
        _jsObserveMap = NSMapTable.strongToStrongObjectsMapTable;
        
        NSMutableDictionary *s = [NSMutableDictionary dictionaryWithDictionary:KSOCObjectTools.sharedTools.scriptHandlers];
        [s addEntriesFromDictionary:self.observerScriptHandlers];
        if (scriptHandlers != nil) {
            [s addEntriesFromDictionary:scriptHandlers];
        }
        _scriptHandlers = s.copy;
        
        WKUserContentController *userContentController = configuration.userContentController;
        NSMutableString *scriptString = NSMutableString.string;
        for (NSString *funcName in s.allKeys) {
            [scriptString appendFormat:@"'%@':function(){var a=[].slice.call(arguments);var r=prompt('__ks_web_bridge_%@',JSON.stringify(a));if(r==null){return null}var k=JSON.parse(r);var e=k.__ks__error;if(e!=undefined||e!=null){throw Error(e)}else{return k}},", funcName, funcName];
        }
        NSString *s1 = [NSString stringWithFormat:@"window.android={%@};", scriptString];
        WKUserScript *script = [WKUserScript.alloc initWithSource:s1 injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [userContentController addUserScript:script];
        
        WKUserScript *ocScript = [WKUserScript.alloc initWithSource:__ks_initJavaScriptString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [userContentController addUserScript:ocScript];
        
        _puppet = __KSWebViewUIDelegatePuppet.alloc;
        super.UIDelegate = _puppet;
        
        UIScrollView *scrollView = self.scrollView;
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
        scrollView.contentInset = UIEdgeInsetsZero;
        scrollView.alwaysBounceHorizontal = NO;
        if (@available(iOS 11.0, *)) {
            scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }

        Class class = NSClassFromString(@"WKContentView");
        for (UIView *view in scrollView.subviews) {
            if ([view isKindOfClass:class]) {
                _webContentView = view;
                break;
            }
        }

        CALayer *progressLayer = CALayer.layer;
        progressLayer.backgroundColor = self.tintColor.CGColor;
        [self.layer addSublayer:progressLayer];
        _progressLayer = progressLayer;

        NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
        [self addObserver:self forKeyPath:__ks__EstimatedProgress options:options context:NULL];
        [self addObserver:self forKeyPath:__ks__WebViewTitle options:options context:NULL];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressLayer.frame = (CGRect){CGPointZero, _progressLayer.bounds.size.width, 4.0};
}

- (void)setUIDelegate:(id<WKUIDelegate>)UIDelegate {
    _puppet.delegate = UIDelegate;
    super.UIDelegate = _puppet;
}

- (id<WKUIDelegate>)UIDelegate {
    return _puppet.delegate;
}

- (void)_runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)body initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * result))completionHandler {
    KSWebViewScriptHandler *handler = [_scriptHandlers objectForKey:prompt];
    id target = handler.target;
    SEL action = handler.action;
    if (target != nil && action != nil && [target respondsToSelector:action]) {
        NSMethodSignature *signature = [target methodSignatureForSelector:action];
        NSArray <id> *arguments = nil;
        if (body != nil && body.length > 0) {
            NSError *error = nil;
            arguments = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (error != nil) {
                completionHandler([KSHelper errorJsonWithError:error]);
                return;
            }
            NSUInteger numberOfArguments = signature.numberOfArguments;
            if (arguments.count != numberOfArguments-2) {
                completionHandler([KSHelper errorJsonWithCode:-998 msg:[NSString stringWithFormat:@"方法：‘%@’，客户端的参数个数与JS不匹配", prompt]]);
                return;
            }
        }
        const char *returnType = signature.methodReturnType;
        BOOL returnVoid = strcmp(returnType, @encode(void)) == 0;
        if (returnVoid) {
            completionHandler(nil);
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = action;
        for (NSInteger i = 0; i < arguments.count; i++) {
            const char *argType = [signature getArgumentTypeAtIndex:i+2];
            id arg = [arguments objectAtIndex:i];
            if (arg == NSNull.null) {// 空
                void *location = NULL;
                [invocation setArgument:location atIndex:i+2];
            } else if (strcmp(argType, @encode(id)) == 0) { // 对象
                [invocation setArgument:&arg atIndex:i+2];
            } else { // 基本数据类型
                NSNumber *number = arg;
                size_t length = __ks_lengthFromType(number.objCType);
                void *location = (void *)malloc(length);
                if (@available(iOS 11.0, *)) {
                    [number getValue:location size:length];
                } else {
                    [number getValue:location];
                }
                [invocation setArgument:location atIndex:i+2];
            }
        }
        [invocation invokeWithTarget:target];
        if (!returnVoid) {
            if (strcmp(returnType, @encode(id)) == 0) {
                void *temp = nil;
                [invocation getReturnValue:&temp];
                completionHandler([KSHelper jsonWithObject:(__bridge id)temp]);
            } else {
                size_t length = signature.methodReturnLength;
                NSNumber *value = __ks_numberFromInvocation(invocation, length, returnType);
                completionHandler([KSHelper jsonWithObject:value]);
            }
        }
    } else {
        completionHandler([KSHelper errorJsonWithCode:-999 msg:[NSString stringWithFormat:@"客户端没有注册'%@'方法", prompt]]);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) {
        if (keyPath == __ks__EstimatedProgress) {
            NSString *url = self.URL.absoluteString;
            if (![url isEqualToString:_ks_BlankPage]) {
                double estimatedProgress = self.estimatedProgress;
                CGRect frame = _progressLayer.frame;
                frame.size.width = self.frame.size.width*estimatedProgress;
                __weak typeof(self) weakSelf = self;
                __weak typeof(_progressLayer) weakView = _progressLayer;
                [UIView animateWithDuration:0.2f animations:^{
                    weakView.frame = frame;
                } completion:^(BOOL finished) {
                    if (estimatedProgress >= 1.f) {
                        [weakSelf resetProgressLayer];
                    } else {
                        weakView.hidden = NO;
                    }
                }];
            }
        } else if (_webViewTitleChangedCallback && keyPath == __ks__WebViewTitle) {
            _webViewTitleChangedCallback(self.title);
        }
    } else {
        KSWebDataStorageModule *sharedModule = KSWebDataStorageModule.sharedModule;
        if (object == sharedModule) {
            NSString *method = [_jsObserveMap objectForKey:keyPath];
            if (method != nil) {
                NSString *old = [KSHelper jsParams:[change objectForKey:@"old"]];
                NSString *new = [KSHelper jsParams:[change objectForKey:@"new"]];
                NSString *js = [NSString stringWithFormat:@"%@(%@,%@)", method, new, old];
                [self evaluateJavaScript:js completionHandler:nil];
            }
        }
    }
}

- (void)resetProgressLayer {
    _progressLayer.hidden = YES;
    CGRect frame = _progressLayer.frame;
    frame.size.width = 0.0;
    _progressLayer.frame = frame;
}

- (WKNavigation *)loadRequest:(NSMutableURLRequest *)request {
    NSDictionary <NSString *, NSString *> *HTTPHeaders = _HTTPHeaders;
    if (HTTPHeaders != nil) {
        NSArray <NSString*>*allKeys = HTTPHeaders.allKeys;
        for (NSString *key in allKeys) {
            NSString *value = [HTTPHeaders objectForKey:key];
            if (value != nil)
                [request addValue:value forHTTPHeaderField:key];
        }
    }
    return [super loadRequest:request];
}

- (void)loadWebViewWithURL:(NSString *)url params:(NSDictionary<NSString *, id> *)params {
    if (url != nil && url.length != 0) {
        if (params != nil) {
            NSMutableString *urlString = [NSMutableString stringWithString:url];
            NSString *bridge = __ks__questionMark;
            if ([urlString rangeOfString:bridge].location != NSNotFound) {
                bridge = __ks__andMark;
            }
            NSMutableString *paramsStr = [NSMutableString stringWithString:bridge];
            NSArray <NSString *> *allKeys = params.allKeys;
            for (NSInteger i = 0; i < allKeys.count; i++) {
                NSString *key = [allKeys objectAtIndex:i];
                NSString *value = [[params objectForKey:key] description];
                [paramsStr appendFormat:@"%@=%@", key, value];
                if (i != allKeys.count-1) {
                    [paramsStr appendString:__ks__andMark];
                }
            }
            [urlString appendString:paramsStr];
            url = urlString;
        }
        NSURL *k_url = [NSURL URLWithString:url];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:k_url];
        [self loadRequest:request];
    }
}

- (void)loadWebViewWithFilePath:(NSString *)filePath {
    if (filePath != nil && filePath.length > 0) {
        NSString *questionMark = __ks__questionMark;
        NSArray <NSString*>*stringArray = [filePath componentsSeparatedByString:questionMark];
        NSURL *fileURL = nil;
        if (stringArray.count > 1) {
            fileURL = [NSURL fileURLWithPath:stringArray.firstObject];
        } else {
            fileURL = [NSURL fileURLWithPath:filePath];
        }
        NSURL *baseURL = fileURL;
        if (stringArray.count > 1) {
            NSString *fileURLString = [NSString stringWithFormat:@"%@%@%@",fileURL.absoluteString,questionMark,stringArray.lastObject];
            baseURL = [NSURL URLWithString:fileURLString];
        }
        [self loadFileURL:baseURL allowingReadAccessToURL:baseURL];
    }
}

- (void)_scriptHandlerSetKeyValues:(NSDictionary <NSString *, id <NSCopying>> *)keyValues {
    if (keyValues != nil && keyValues.count > 0) {
        [KSWebDataStorageModule.sharedModule addEntriesFromDictionary:keyValues];
    }
}

- (void)_scriptHandlerSetValue:(id <NSCopying>)value forKey:(NSString *)key {
    if (value != nil && key != nil && key.length > 0) {
        [KSWebDataStorageModule.sharedModule setObject:value forKey:key];
    }
}

- (id <NSCopying>)_scriptHandlerGetValue:(NSString *)key {
    if (key != nil && key.length > 0) {
        return [KSWebDataStorageModule.sharedModule objectForKey:key];
    }
    return nil;
}

- (void)_scriptHandlerAddObserverWithKey:(NSString *)key callback:(NSString *)callback {
    if (key != nil && key.length > 0 && callback != nil && callback.length > 0) {
        [_jsObserveMap setObject:callback forKey:key];
        [KSWebDataStorageModule.sharedModule addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    }
}

- (void)_scriptHandlerRemoveObserverWithKey:(NSString *)key {
    if (key != nil && key.length > 0) {
        [_jsObserveMap removeObjectForKey:key];
        [KSWebDataStorageModule.sharedModule removeObserver:self forKeyPath:key context:nil];
    }
}

- (void)_scriptHandlerRemoveAllObserver {
    KSWebDataStorageModule *sharedModule = KSWebDataStorageModule.sharedModule;
    for (NSString *key in _jsObserveMap) {
        [sharedModule removeObserver:self forKeyPath:key context:nil];
    }
}

- (void)_scriptHandlerreInitDataStorage {
    [KSWebDataStorageModule.sharedModule removeAllObjects];
}

- (NSDictionary<NSString *,KSWebViewScriptHandler *> *)observerScriptHandlers {
    KSWebViewScriptHandler *setKeyValues = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerSetKeyValues:)];
    KSWebViewScriptHandler *setValue = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerSetValue:forKey:)];
    KSWebViewScriptHandler *getValue = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerGetValue:)];
    KSWebViewScriptHandler *addObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerAddObserverWithKey:callback:)];
    KSWebViewScriptHandler *removeObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerRemoveObserverWithKey:)];
    KSWebViewScriptHandler *removeAllObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerRemoveAllObserver)];
    KSWebViewScriptHandler *reinit = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(_scriptHandlerreInitDataStorage)];
    return @{@"setKeyValues": setKeyValues, @"setValue": setValue, @"getValue": getValue, @"addObserver": addObserver, @"removeObserver": removeObserver, @"removeAllObserver": removeAllObserver, @"reinit": reinit};
}

- (void)webViewBeginScreenshot {
    CALayer *layer = self.layer;
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageView *screenshotView = _screenshotView;
    if (screenshotView == nil) {
        screenshotView = [[UIImageView alloc]init];
        screenshotView.backgroundColor = [UIColor whiteColor];
        [self addSubview:screenshotView];
        _screenshotView = screenshotView;
    }
    screenshotView.image = img;
    screenshotView.frame = self.bounds;
    screenshotView.hidden = NO;
}

- (void)webViewEndScreenshot {
    UIImageView *screenshotView = _screenshotView;
    if (screenshotView) screenshotView.hidden = YES;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:__ks__EstimatedProgress];
    [self removeObserver:self forKeyPath:__ks__WebViewTitle];
    [self _scriptHandlerRemoveAllObserver];
}

- (void)videoPlayerCount:(void (^)(NSInteger))callback {
    if (callback != nil) {
        NSString * hasVideoTestString = [NSString stringWithFormat:@"%@.length",__ks__GetVideoTag];
        [self evaluateJavaScript:hasVideoTestString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
            if (callback != nil) callback(result.unsignedIntegerValue);
        }];
    }
}

- (void)videoDurationWithIndex:(NSInteger)index callback:(void(^)(double))callback {
    if (callback != nil) {
        __weak typeof(self) weakSelf = self;
        [self videoPlayerCount:^(NSInteger count) {
            if (index < count) {
                NSString * durationString = [NSString stringWithFormat:@"%@[%td].duration.toFixed(1)", __ks__GetVideoTag, index];
                [weakSelf evaluateJavaScript:durationString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
                    if (callback != nil) callback(result.doubleValue);
                }];
            }
        }];
    }
}

- (void)videoCurrentTimeWithIndex:(NSInteger)index callback:(void(^)(double))callback {
    if (callback != nil) {
        __weak typeof(self) weakSelf = self;
        [self videoPlayerCount:^(NSInteger count) {
            if (index < count) {
                NSString * durationString = [NSString stringWithFormat:@"%@[%td].currentTime.toFixed(1)", __ks__GetVideoTag, index];
                [weakSelf evaluateJavaScript:durationString completionHandler:^(NSNumber *result, NSError * _Nullable error) {
                    if (callback != nil) callback(result.doubleValue);
                }];
            }
        }];
    }
}

- (void)playVideoWithIndex:(NSInteger)index {
    __weak typeof(self) weakSelf = self;
    [self videoPlayerCount:^(NSInteger count) {
        if (index < count) {
            NSString *playString = [NSString stringWithFormat:@"%@[%td].play()", __ks__GetVideoTag, index];
            [weakSelf evaluateJavaScript:playString completionHandler:nil];
        }
    }];
}

- (void)pausePlayingVideo {
    __weak typeof(self) weakSelf = self;
    [self videoPlayerCount:^(NSInteger count) {
        if (count > 0) {
            NSString *pauseString = [NSString stringWithFormat:@"var dom = %@;for(var i = 0; i < dom.length; i++){dom[i].pause();}", __ks__GetVideoTag];
            [weakSelf evaluateJavaScript:pauseString completionHandler:nil];
        }
    }];
}

@end
