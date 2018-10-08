//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _WDObserverModel : NSObject

@property (nonatomic, weak) id observer;
-(void)executeWithArg:(id)arg oldArg:(id)oldArg;

@end

@implementation _WDObserverModel -(void)executeWithArg:(id)arg oldArg:(id)oldArg {} @end

@interface _WDClientObserverModel : _WDObserverModel

@property (nonatomic, copy) void (^callback)(NSString *value, NSString *oldValue);

@end

@implementation _WDClientObserverModel

-(void)executeWithArg:(id)arg oldArg:(id)oldArg {
    if (self.observer != nil && _callback != nil) {
        _callback(arg, oldArg);
    }
}

@end

#import "KSWebView.h"

@interface _WDHtmlObserverModel : _WDObserverModel

@property (nonatomic, copy) NSString *JSMethodName;

@end

@implementation _WDHtmlObserverModel

-(void)executeWithArg:(id)arg oldArg:(id)oldArg {
    KSWebView *webView = self.observer;
    if (webView != nil && _JSMethodName != nil) {
        NSString *js = nil;
        if (oldArg) {
            js = [NSString stringWithFormat:@"%@','%@','%@", _JSMethodName, arg, oldArg];
        } else {
            js = [NSString stringWithFormat:@"%@','%@", _JSMethodName, arg];
        }
        [webView evaluateJavaScriptMethod:js completionHandler:nil];
    }
}

@end

#import "KSWebDataStorageModule.h"
#import "KSWebViewScriptHandler.h"
#import "MJExtension.h"

@interface KSWebDataStorageModule ()

@property (nonatomic, strong, readonly) NSMutableDictionary <NSString*, NSString*>*dataPool;
@property (nonatomic, copy, readonly) NSString *dataPoolLockToken;
@property (nonatomic, strong, readonly) NSMutableDictionary <NSString*, NSMutableArray<_WDObserverModel*>*>*observerPool;
@property (nonatomic, copy, readonly) NSString *observerPoolLockToken;
@property (nonatomic, strong, readonly) NSDictionary <NSString*,KSWebViewScriptHandler*>*scriptHandlers;

@end

@implementation KSWebDataStorageModule
@synthesize dataPool = _dataPool, observerPool = _observerPool, scriptHandlers = _scriptHandlers,
dataPoolLockToken = _dataPoolLockToken, observerPoolLockToken = _observerPoolLockToken;

static KSWebDataStorageModule *_instance;
+(instancetype)shareInstance {
    if (_instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc]init];
        });
    }
    return _instance;
}

+(void)setValue:(NSString*)value forKey:(NSString*)key {
    [[self shareInstance] WD_setValue:value forKey:key];
}

-(void)WD_setValue:(NSString*)value forKey:(NSString*)key {
    if (value != nil && key != nil) {
        NSString *stringValue = value.description;
        NSMutableDictionary <NSString*, NSString*>*dataPool = self.dataPool;
        NSString *oldValue = nil;
        @synchronized (self.dataPoolLockToken) {
            oldValue = [dataPool objectForKey:key];
            [dataPool setObject:stringValue forKey:key];
        }
        NSMutableDictionary<NSString*,NSMutableArray<_WDObserverModel*>*>*observerPool = self.observerPool;
        @synchronized (self.observerPoolLockToken) {
            NSMutableArray <_WDObserverModel*>*observerArray = [observerPool objectForKey:key];
            if (observerArray != nil && observerArray.count != 0) {
                for (_WDObserverModel *model in observerArray) {
                    [model executeWithArg:stringValue oldArg:oldValue];
                }
            }
        }
    }
}

+(void)setKeyValueDictionary:(NSDictionary*)dictionary {
    [[self shareInstance] WD_setKeyValueDictionary:dictionary];
}

-(void)WD_setKeyValueDictionary:(NSDictionary*)dictionary {
    NSArray *allKeys = dictionary.allKeys;
    if (allKeys != nil && allKeys.count != 0) {
        NSMutableDictionary <NSString*, NSString*>*dataPool = self.dataPool;
        NSMutableDictionary<NSString*,NSMutableArray<_WDObserverModel*>*>*observerPool = self.observerPool;
        for (NSString *key in allKeys) {
            NSString *value = [dictionary objectForKey:key];
            NSString *stringValue = value.description;
            NSString *oldValue = nil;
            @synchronized (self.dataPoolLockToken) {
                oldValue = [dataPool objectForKey:key];
                [dataPool setObject:stringValue forKey:key];
            }
            @synchronized (self.observerPoolLockToken) {
                NSMutableArray <_WDObserverModel*>*observerArray = [observerPool objectForKey:key];
                if (observerArray != nil && observerArray.count != 0) {
                    for (_WDObserverModel *model in observerArray) {
                        [model executeWithArg:stringValue oldArg:oldValue];
                    }
                }
            }
        }
    }
}

+(NSString*)valueForKey:(NSString*)key {
    KSWebDataStorageModule *storage = [self shareInstance];
    return [storage.dataPool objectForKey:key];
}

+(void)WD_addObserverModel:(_WDObserverModel*)model forKeyPath:(NSString*)keyPath {
    KSWebDataStorageModule *storage = [self shareInstance];
    NSMutableDictionary<NSString*,NSMutableArray<_WDObserverModel*>*>*observerPool = storage.observerPool;
    @synchronized (storage.observerPoolLockToken) {
        NSMutableArray <_WDObserverModel*>*observerArray = [observerPool objectForKey:keyPath];
        if (observerArray) {
            for (_WDObserverModel *k_model in observerArray) {
                if (k_model.observer == model.observer) return;
            }
        } else {
            observerArray = [NSMutableArray array];
            [observerPool setObject:observerArray forKey:keyPath];
        }
        [observerArray addObject:model];
    }
}

+(void)addObserverWebView:(KSWebView*)webView JSMethodName:(NSString*)JSMethodName forKeyPath:(NSString*)keyPath {
    _WDHtmlObserverModel *model = [[_WDHtmlObserverModel alloc]init];
    model.observer = webView;
    model.JSMethodName = JSMethodName;
    [self WD_addObserverModel:model forKeyPath:keyPath];
}

+(void)removeObserverWebView:(KSWebView*)webView forKeyPath:(NSString*)keyPath {
    [self removeObserver:webView forKeyPath:keyPath];
}

+(void)addObserver:(id)observer callback:(void(^)(NSString *value, NSString *oldValue))callback forKeyPath:(NSString*)keyPath {
    _WDClientObserverModel *model = [[_WDClientObserverModel alloc]init];
    model.observer = observer;
    model.callback = callback;
    [self WD_addObserverModel:model forKeyPath:keyPath];
}

+(void)removeObserver:(id)observer forKeyPath:(NSString*)keyPath {
    KSWebDataStorageModule *storage = [self shareInstance];
    NSMutableDictionary<NSString*,NSMutableArray<_WDObserverModel*>*>*observerPool = storage.observerPool;
    @synchronized (storage.observerPoolLockToken) {
        NSMutableArray <_WDObserverModel*>*observerArray = [observerPool objectForKey:keyPath];
        if (observerArray) {
            for (_WDObserverModel *model in observerArray) {
                if (model.observer == observer) {
                    [observerArray removeObject:model];
                    break;
                }
            }
            if (observerArray.count <= 0) {
                [observerPool removeObjectForKey:keyPath];
            }
        }
    }
}

+(void)removeObserver:(id)observer {
    KSWebDataStorageModule *storage = [self shareInstance];
    NSMutableDictionary <NSString*,NSMutableArray<_WDObserverModel*>*>*observerPool = storage.observerPool;
    NSArray <NSString*>*allKeys = observerPool.allKeys;
    if (allKeys.count) {
        @synchronized (storage.observerPoolLockToken) {
            for (NSString *key in allKeys) {
                NSMutableArray <_WDObserverModel*>*observerArray = [observerPool objectForKey:key];
                NSMutableArray <_WDObserverModel*>*removeObserverArray = [NSMutableArray array];
                for (_WDObserverModel *model in observerArray) {
                    id model_observer = model.observer;
                    if (model_observer == observer || model_observer == nil) {
                        [removeObserverArray addObject:model];
                    }
                }
                [observerArray removeObjectsInArray:removeObserverArray];
                if (observerArray.count <= 0) {
                    [observerPool removeObjectForKey:key];
                }
            }
        }
    }
}

+(void)scriptHandlerSetValue:(WKScriptMessage*)message {
    NSString *body = message.body;
    if (body.length) {
        NSDictionary *dict = [body mj_JSONObject];
        NSArray *allKeys = dict.allKeys;
        if (allKeys.count > 1) {
            [self setKeyValueDictionary:dict];
        } else {
            NSString *key = allKeys.firstObject;
            NSString *value = [dict objectForKey:key];
            [self setValue:value forKey:key];
        }
    }
}

+(NSString*)scriptHandlerGetValue:(WKScriptMessage*)message {
    NSString *body = message.body;
    if (body.length) {
        return [self valueForKey:body];
    }
    return nil;
}

+(void)scriptHandlerAddObserver:(WKScriptMessage*)message {
    NSString *body = message.body;
    if (body.length) {
        KSWebView *webView = (KSWebView*)message.webView;
        NSDictionary *dict = [body mj_JSONObject];
        NSString *keyPath = dict.allKeys.firstObject;
        NSString *JSMethodName = [dict objectForKey:keyPath];
        [self addObserverWebView:webView JSMethodName:JSMethodName forKeyPath:keyPath];
    }
}

+(void)scriptHandlerRemoveObserver:(WKScriptMessage*)message {
    NSString *body = message.body;
    if (body.length) {
        KSWebView *webView = (KSWebView*)message.webView;
        [self removeObserverWebView:webView forKeyPath:body];
    }
}

+(void)scriptHandlerRemoveCurrentObserver:(WKScriptMessage*)message {
    KSWebView *webView = (KSWebView*)message.webView;
    [self removeObserver:webView];
}

+(void)scriptHandlerreinitDataStorage {
    KSWebDataStorageModule *storage = [self shareInstance];
    NSMutableDictionary <NSString *,NSMutableArray<_WDObserverModel *> *> *observerPool = storage.observerPool;
    @synchronized (storage.observerPoolLockToken) {
        if (observerPool && observerPool.allKeys.count)
            [observerPool removeAllObjects];
    }
    NSMutableDictionary<NSString *,NSString *> *dataPool = storage.dataPool;
    @synchronized (storage.dataPoolLockToken) {
        if (dataPool.allKeys.count)
            [dataPool removeAllObjects];
    }
}

-(NSMutableDictionary<NSString *,NSMutableArray<_WDObserverModel *> *> *)observerPool {
    if (!_observerPool) {
        _observerPool = [NSMutableDictionary dictionary];
    }
    return _observerPool;
}

-(NSMutableDictionary<NSString *,NSString *> *)dataPool {
    if (!_dataPool) {
        _dataPool = [NSMutableDictionary dictionary];
    }
    return _dataPool;
}

-(NSString *)dataPoolLockToken {
    if (_dataPoolLockToken == nil) {
        _dataPoolLockToken = [NSString stringWithFormat:@"dataPoolLockToken"];
    }
    return _dataPoolLockToken;
}

-(NSString *)observerPoolLockToken {
    if (_observerPoolLockToken == nil) {
        _observerPoolLockToken = [NSString stringWithFormat:@"observerPoolLockToken"];
    }
    return _observerPoolLockToken;
}

-(NSDictionary<NSString *,KSWebViewScriptHandler *> *)scriptHandlers {
    if (!_scriptHandlers) {
        Class class = self.class;
        KSWebViewScriptHandler *setValue = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerSetValue:)];
        KSWebViewScriptHandler *getValue = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerGetValue:)];
        KSWebViewScriptHandler *addObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerAddObserver:)];
        KSWebViewScriptHandler *removeObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerRemoveObserver:)];
        KSWebViewScriptHandler *removeCurrentObserver = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerRemoveCurrentObserver:)];
        KSWebViewScriptHandler *reInit = [KSWebViewScriptHandler scriptHandlerWithTarget:class action:@selector(scriptHandlerreinitDataStorage)];
        _scriptHandlers = @{@"setValue":setValue, @"getValue":getValue, @"addObserver":addObserver, @"removeObserver":removeObserver, @"removeCurrentObserver":removeCurrentObserver, @"reInit":reInit};
    }
    return _scriptHandlers;
}

+(NSDictionary<NSString *,KSWebViewScriptHandler *> *)scriptHandlers {
    return [KSWebDataStorageModule shareInstance].scriptHandlers;
}

@end
