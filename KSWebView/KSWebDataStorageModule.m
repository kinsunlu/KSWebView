//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebView.h"
#import "KSWebDataStorageModule.h"

@implementation KSWebDataStorageModule {
    NSMapTable <NSString*, id<NSCopying>>*_dataPool;
    NSLock *_dataPoolLock;
}

+ (instancetype)sharedModule {
    static KSWebDataStorageModule *_instance = nil;
    if (_instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dataPool = NSMapTable.strongToStrongObjectsMapTable;
        _dataPoolLock = NSLock.alloc.init;
    }
    return self;
}

- (void)setObject:(id<NSCopying>)object forKey:(NSString *)key {
    if (key != nil && key.length > 0) {
        [_dataPoolLock lock];
        [self willChangeValueForKey:key];
        if (object == nil) {
            [_dataPool removeObjectForKey:key];
        } else {
            [_dataPool setObject:object forKey:key];
        }
        [self didChangeValueForKey:key];
        [_dataPoolLock unlock];
    }
}

- (void)addEntriesFromDictionary:(NSDictionary<NSString *,id<NSCopying>> *)dictionary {
    if (dictionary != nil && dictionary.count != 0) {
        [_dataPoolLock lock];
        [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<NSCopying> obj, BOOL *stop) {
            [self willChangeValueForKey:key];
            [_dataPool setObject:obj forKey:key];
            [self didChangeValueForKey:key];
        }];
        [_dataPoolLock unlock];
    }
}

- (id<NSCopying>)objectForKey:(NSString *)key {
    return [_dataPool objectForKey:key];
}

- (void)removeAllObjects {
    [_dataPoolLock lock];
    [_dataPool removeAllObjects];
    [_dataPoolLock unlock];
}

- (NSUInteger)count {
    return _dataPool.count;
}

- (NSArray *)allKeys {
    return NSAllMapTableKeys(_dataPool);
}

- (NSArray *)allValues {
    return NSAllMapTableValues(_dataPool);
}

@end
