//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebView.h"

@interface _KSWebViewMemoryManagerItem : NSObject

@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;
@property (nonatomic, strong, readonly) KSWebView *webView;

@end

@implementation _KSWebViewMemoryManagerItem

+(instancetype)itemWithTimeInterval:(NSTimeInterval)timeInterval webView:(KSWebView*)webView {
    _KSWebViewMemoryManagerItem *item = [[self alloc]init];
    item->_timeInterval = timeInterval;
    item->_webView = webView;
    return item;
}

@end

#import "KSWebViewMemoryManager.h"

@interface KSWebViewMemoryManager () {
    NSTimer *_timer;
}

@property (nonatomic, strong) NSMutableArray <_KSWebViewMemoryManagerItem*>*webViewPool;
@property (nonatomic, readonly, class) dispatch_queue_t queue;

@end

@implementation KSWebViewMemoryManager

static KSWebViewMemoryManager *_instance;
+(instancetype)shareInstance {
    if (_instance == nil) {
        _instance = [[self alloc]init];
    }
    return _instance;
}

+(void)addWebView:(KSWebView*)webView {
    if (webView) {
        KSWebViewMemoryManager *mgr = [self shareInstance];
        NSLog(@"webView:\"%@\"被创建,并且加入webViewPool",webView);
        NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
        _KSWebViewMemoryManagerItem *item = [_KSWebViewMemoryManagerItem itemWithTimeInterval:nowTime webView:webView];
        [mgr.webViewPool addObject:item];
        NSLog(@"webViewPool中已有%zd个对象",mgr.webViewPool.count);
        [mgr startChecking];
    }
}

-(void)startChecking {
    if (!_timer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:60.f target:self selector:@selector(checkReleaseInWebViewPool) userInfo:nil repeats:YES];
        NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
        [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
        _timer = timer;
    }
}

-(void)stopChecking {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void)checkReleaseInWebViewPool {
    dispatch_async(KSWebViewMemoryManager.queue, ^{
        NSMutableArray <_KSWebViewMemoryManagerItem*>*webViewPool = self.webViewPool;
        NSLog(@"正在检查webViewPool,现有%zd个对象在池中",webViewPool.count);
        NSMutableArray <_KSWebViewMemoryManagerItem*>*releasePool = [NSMutableArray array];
        NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
        for (_KSWebViewMemoryManagerItem *item in webViewPool.mutableCopy) {
            NSTimeInterval itemTime = item.timeInterval;
            if (nowTime - itemTime > 10.f) {
                KSWebView *webView = item.webView;//模型内一个引用,现在这个指针一个引用所以是2
                NSUInteger count = [[webView valueForKey:@"retainCount"] unsignedIntegerValue];
                if (count <= 2 && !webView.isLoading) {
                    [releasePool addObject:item];
                }
            }
        }
        if (releasePool.count) {
            NSLog(@"检查有%zd个webView没有引用正在释放...",releasePool.count);
            [webViewPool removeObjectsInArray:releasePool];
        }
        if (!webViewPool.count) {
            [self stopChecking];
        }
    });
}

-(NSMutableArray<_KSWebViewMemoryManagerItem *> *)webViewPool {
    if (!_webViewPool) {
        _webViewPool = [NSMutableArray array];
    }
    return _webViewPool;
}

+(dispatch_queue_t)queue {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

@end
