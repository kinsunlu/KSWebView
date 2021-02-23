//
//  KSOCObjectTools.m
//  KSWebViewDemo
//
//  Created by kinsun on 2018/8/27.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSOCObjectTools.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface _KSOCMethodModel : NSObject

@property (nonatomic, readonly) SEL selector;
@property (nonatomic, copy, readonly) NSString *selectorString;
@property (nonatomic, assign, readonly, getter=isClassMethod) BOOL classMethod;

@end

@implementation _KSOCMethodModel

- (instancetype)initWithMethod:(Method)method classMethod:(BOOL)isClassMethod {
    if (self = [super init]) {
        SEL selector = method_getName(method);
        _selector = selector;
        _selectorString = NSStringFromSelector(selector);
        _classMethod = isClassMethod;
    }
    return self;
}

@end

@interface _KSOCObject : NSObject

@property (nonatomic, strong, readonly) id objectValue;
@property (nonatomic, assign, readonly) void *locationValue;
@property (nonatomic, assign, readonly) BOOL isObject;

@end

@implementation _KSOCObject

+ (instancetype)objectFromValue:(id)objectValue {
    _KSOCObject *object = [[_KSOCObject alloc]init];
    object->_objectValue = objectValue;
    object->_isObject = YES;
    return object;
}

+ (instancetype)locationFromValue:(void *)locationValue {
    _KSOCObject *object = [[_KSOCObject alloc]init];
    object->_locationValue = locationValue;
    object->_isObject = NO;
    return object;
}

- (void)dealloc {
    _objectValue = nil;
    _locationValue = NULL;
}

- (NSString *)description {
    if (_isObject) {
        return [_objectValue description];
    } else {
        return [NSString stringWithFormat:@"%p", _locationValue];
    }
}

@end

@interface _KSOCClassInfoModel : NSObject

@property (nonatomic, strong) NSDictionary <NSString*, _KSOCMethodModel*>*classMethod;
@property (nonatomic, strong) NSDictionary <NSString*, _KSOCMethodModel*>*instanceMethod;

@end

@implementation _KSOCClassInfoModel @end

@interface _KSOCInvokeModel : NSObject

@property (nonatomic, copy, readonly) NSString *objKey;
@property (nonatomic, copy, readonly) NSString *funcName;
@property (nonatomic, copy, readonly) NSString *className;
@property (nonatomic, strong, readonly) NSMutableArray *params;

@end

@implementation _KSOCInvokeModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _objKey = [dictionary objectForKey:@"objKey"];
        _funcName = [dictionary objectForKey:@"funcName"];
        _className = [dictionary objectForKey:@"className"];
        _params = [[dictionary objectForKey:@"params"] mutableCopy];
    }
    return self;
}

@end

static NSString * k_initJavaScriptString = @"window.OCTools=function(){var tools={};tools['importClass']=window.__ksImportClass;tools['releaseObjects']=window.android.__ks_releaseObjects;tools.OCClass={};return tools}();function __ksInvokeOCObject(value,k_arguments,isClass){if(isClass){this.className=value}else{this.objKey=value}this.funcName=k_arguments.callee.__ks_funcName;this.params=Array.prototype.slice.call(k_arguments)}function __ksImportClass(classString){var occlass=window.OCTools.OCClass;var oc_class_obj=occlass[classString];if(oc_class_obj===null||oc_class_obj===undefined){var obj=window.android.__ks_importClass(classString);var oc_instance=obj.instance;function ks_oc_object(objKey){this.__ks_objKey=objKey}var instance_prototype=ks_oc_object.prototype;for(var i in oc_instance){var item=oc_instance[i];function func(){var objKey=this.__ks_objKey;var value=new __ksInvokeOCObject(objKey,arguments,false);return __ksInvokeOCMethod(value)}func.__ks_funcName=item;instance_prototype[item]=func}var oc_class=obj.class;function ks_oc_class(className,instanceMethod){this.__ks_className=className;this.__ks_instance_method=instanceMethod}var class_prototype=ks_oc_class.prototype;for(var i in oc_class){var item=oc_class[i];function func(){var className=this.__ks_className;var value=new __ksInvokeOCObject(className,arguments,true);return __ksInvokeOCMethod(value)}func.__ks_funcName=item;class_prototype[item]=func}oc_class_obj=new ks_oc_class(classString,ks_oc_object);occlass[classString]=oc_class_obj}return oc_class_obj}function __ksGetMethodReturn(oc_class,objKey){var oc_instance_obj;if(oc_class!==undefined&&oc_class!==null){var oc_instance=oc_class.__ks_instance_method;oc_instance_obj=new oc_instance(objKey)}else{oc_instance_obj=new Object;oc_instance_obj.__ks_objKey=objKey}return oc_instance_obj}function __ksInvokeOCMethod(value){var returnData=window.android.__ks_invokeMethod(value);if(returnData!==undefined&&returnData!==null){var type=returnData.type;switch(type){case'object':{var tools=window.OCTools;var occlass=tools.OCClass;var returnClass=returnData.className;var k_class=occlass[returnClass];if(k_class===null||k_class===undefined){k_class=tools.importClass(returnClass);occlass[returnClass]=k_class}var returnObj=returnData.objKey;var k_obj=__ksGetMethodReturn(k_class,returnObj);return k_obj}case'other':{var returnObj=returnData.objKey;var k_obj=__ksGetMethodReturn(null,returnObj);return k_obj}default:return returnData.value}}}";

size_t __ks_lengthFromType(const char *type) {
    if (strcmp(type, @encode(int)) == 0) {
        return sizeof(int);
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        return sizeof(unsigned int);
    } else if (strcmp(type, @encode(long)) == 0) {
        return sizeof(long);
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        return sizeof(unsigned long);
    } else if (strcmp(type, @encode(long long)) == 0) {
        return sizeof(long long);
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        return sizeof(unsigned long long);
    } else if (strcmp(type, @encode(float)) == 0) {
        return sizeof(float);
    } else if (strcmp(type, @encode(double)) == 0) {
        return sizeof(double);
    } else if (strcmp(type, @encode(BOOL)) == 0) {
        return sizeof(BOOL);
    } else if (strcmp(type, @encode(NSInteger)) == 0) {
        return sizeof(NSInteger);
    } else if (strcmp(type, @encode(NSUInteger)) == 0) {
        return sizeof(NSUInteger);
    } else if (strcmp(type, @encode(char)) == 0) {
        return sizeof(char);
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        return sizeof(unsigned char);
    } else if (strcmp(type, @encode(short)) == 0) {
        return sizeof(short);
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        return sizeof(unsigned short);
    } else return 16;
}

NSNumber * __ks_numberFromInvocation(NSInvocation *invocation, size_t length, const char *type) {
    void *buffer = (void *)malloc(length);
    [invocation getReturnValue:buffer];
    if (strcmp(type, @encode(int)) == 0) {
        return [NSNumber numberWithInt:*((int*)buffer)];
    } else if (strcmp(type, @encode(unsigned int)) == 0) {
        return [NSNumber numberWithUnsignedInt:*((unsigned int*)buffer)];
    } else if (strcmp(type, @encode(long)) == 0) {
        return [NSNumber numberWithLong:*((long*)buffer)];
    } else if (strcmp(type, @encode(unsigned long)) == 0) {
        return [NSNumber numberWithUnsignedLong:*((unsigned long*)buffer)];
    } else if (strcmp(type, @encode(long long)) == 0) {
        return [NSNumber numberWithLongLong:*((long long*)buffer)];
    } else if (strcmp(type, @encode(unsigned long long)) == 0) {
        return [NSNumber numberWithUnsignedLongLong:*((unsigned long long*)buffer)];
    } else if (strcmp(type, @encode(float)) == 0) {
        return [NSNumber numberWithFloat:*((float*)buffer)];
    } else if (strcmp(type, @encode(double)) == 0) {
        return [NSNumber numberWithDouble:*((double*)buffer)];
    } else if (strcmp(type, @encode(BOOL)) == 0) {
        return [NSNumber numberWithBool:*((BOOL*)buffer)];
    } else if (strcmp(type, @encode(NSInteger)) == 0) {
        return [NSNumber numberWithInteger:*((NSInteger*)buffer)];
    } else if (strcmp(type, @encode(NSUInteger)) == 0) {
        return [NSNumber numberWithUnsignedInteger:*((NSUInteger*)buffer)];
    } else if (strcmp(type, @encode(char)) == 0) {
        return [NSNumber numberWithChar:*((char*)buffer)];
    } else if (strcmp(type, @encode(unsigned char)) == 0) {
        return [NSNumber numberWithUnsignedChar:*((unsigned char*)buffer)];
    } else if (strcmp(type, @encode(short)) == 0) {
        return [NSNumber numberWithShort:*((short*)buffer)];
    } else if (strcmp(type, @encode(unsigned short)) == 0) {
        return [NSNumber numberWithUnsignedShort:*((unsigned short*)buffer)];
    }
    return nil;
}

NSString * const k_colon            = @":";
NSString * const k_empty            = @"";
NSString * const k_location_format  = @"%p";
NSString * const k_class            = @"class";
NSString * const k_instance         = @"instance";
NSString * const k_objKey           = @"objKey";
NSString * const k_js_objKey        = @"__ks_objKey";
NSString * const k_className        = @"className";
NSString * const k_value            = @"value";
NSString * const k_type             = @"type";
NSString * const k_other            = @"other";
NSString * const k_object           = @"object";
NSString * const k_base             = @"base";

#import <WebKit/WKScriptMessage.h>
#import "KSWebViewScriptHandler.h"

@interface KSOCObjectTools ()

@property (nonatomic, strong, readonly) NSMapTable <NSString *, _KSOCClassInfoModel*>*catalog;
@property (nonatomic, readonly, copy) NSString *catalogLockToken;
@property (nonatomic, strong, readonly) NSMapTable <NSString *, _KSOCObject*>*objectPool;
@property (nonatomic, readonly, copy) NSString *objectPoolLockToken;

@end

@implementation KSOCObjectTools
@synthesize catalog = _catalog, objectPool = _objectPool,
catalogLockToken = _catalogLockToken, objectPoolLockToken = _objectPoolLockToken;

+ (instancetype)share {
    static KSOCObjectTools *_instance = nil;
    if (_instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
        });
    }
    return _instance;
}

+ (NSDictionary *)scriptHandlerImportClass:(NSString *)className {
    if (className != nil && className.length != 0) {
        Class class = NSClassFromString(className);
        if (class != nil) {
            KSOCObjectTools *tools = KSOCObjectTools.share;
            NSMapTable <NSString *,_KSOCClassInfoModel*>*catalog = tools.catalog;
            NSMutableSet <NSString*>* classMethodNameArray = NSMutableSet.set;
            NSMutableSet <NSString*>* instanceMethodNameArray = NSMutableSet.set;
            while (class != nil) {
                NSString *classNameKey = NSStringFromClass(class);
                _KSOCClassInfoModel *info = [catalog objectForKey:classNameKey];
                if (info == nil) {
                    info = [self methodFromClass:class];
                    @synchronized (tools.catalogLockToken) {
                        [catalog setObject:info forKey:classNameKey];
                    }
                }
                [classMethodNameArray addObjectsFromArray:info.classMethod.allKeys];
                [instanceMethodNameArray addObjectsFromArray:info.instanceMethod.allKeys];
                class = [class superclass];
            }
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:classMethodNameArray.allObjects, k_class, instanceMethodNameArray.allObjects, k_instance, nil];
            return dict;
        }
    }
    return nil;
}

+ (_KSOCClassInfoModel *)methodFromClass:(Class)class {
    NSMutableDictionary <NSString *,_KSOCMethodModel *>* instanceMethod = [NSMutableDictionary dictionary];
    unsigned int count;
    Method *instance_methods = class_copyMethodList(class, &count);
    for (int i = 0; i < count; i++) {
        Method method = instance_methods[i];
        _KSOCMethodModel *model = [_KSOCMethodModel.alloc initWithMethod:method classMethod:NO];
        NSString *key = [model.selectorString stringByReplacingOccurrencesOfString:k_colon withString:k_empty];
        [instanceMethod setValue:model forKey:key];
    }
    NSMutableDictionary <NSString *,_KSOCMethodModel *>* classMethod = [NSMutableDictionary dictionary];
    Class metaClass = object_getClass(class);
    Method *class_methods = class_copyMethodList(metaClass, &count);
    for (int i = 0; i < count; i++) {
        Method method = class_methods[i];
        _KSOCMethodModel *model = [_KSOCMethodModel.alloc initWithMethod:method classMethod:YES];
        NSString *key = [model.selectorString stringByReplacingOccurrencesOfString:k_colon withString:k_empty];
        [classMethod setValue:model forKey:key];
    }
    _KSOCClassInfoModel *model = _KSOCClassInfoModel.alloc.init;
    model.classMethod = classMethod;
    model.instanceMethod = instanceMethod;
    return model;
}

+ (NSDictionary *)scriptHandlerInvokeClassMethod:(NSDictionary *)params {
    if (params != nil && params.count != 0) {
        _KSOCInvokeModel *model = [_KSOCInvokeModel.alloc initWithDictionary:params];
        NSString *funcName = model.funcName;
        NSString *className = model.className;
        NSString *objKey = model.objKey;
        KSOCObjectTools *tools = KSOCObjectTools.share;
        NSMapTable <NSString *, _KSOCObject*>*objectPool = tools.objectPool;
        SEL selector = nil;
        id target = nil;
        NSMethodSignature *signature = nil;
        if (className != nil && className.length != 0) {
            Class class = NSClassFromString(model.className);
            _KSOCMethodModel *obj_model = [self searchClass:class isClass:YES method:funcName inCatalog:tools.catalog];
            selector = obj_model.selector;
            signature = [class methodSignatureForSelector:selector];
            target = class;
        } else if (objKey != nil && objKey.length != 0) {
            _KSOCObject *obj = [objectPool objectForKey:objKey];
            target = obj.objectValue;
            Class class = [target class];
            _KSOCMethodModel *obj_model = [self searchClass:class isClass:NO method:funcName inCatalog:tools.catalog];
            selector = obj_model.selector;
            signature = [class instanceMethodSignatureForSelector:selector];
        }
        if (selector != nil && target != nil) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = selector;
            NSArray *params = model.params;
            for (NSInteger i = 0; i < params.count; i++) {
                void *paramLocation = NULL;
                id param = [params objectAtIndex:i];
                if (param == NSNull.null) {
                    param = nil;
                } else if ([param isKindOfClass:NSDictionary.class]) {
                    NSDictionary *dict = param;
                    NSString *objKey = [dict objectForKey:k_js_objKey];
                    if (objKey != nil) {
                        _KSOCObject *obj = [objectPool objectForKey:objKey];
                        if (obj.isObject) {
                            param = obj.objectValue;
                        } else {
                            paramLocation = obj.locationValue;
                        }
                    }
                } else if ([param isKindOfClass:NSNumber.class]) {
                    NSNumber *number = param;
                    size_t length = __ks_lengthFromType(number.objCType);
                    paramLocation = (void *)malloc(length);
                    if (@available(iOS 11.0, *)) {
                        [number getValue:paramLocation size:length];
                    } else {
                        [number getValue:paramLocation];
                    }
                }
                if (paramLocation == NULL) paramLocation = &param;
                [invocation setArgument:paramLocation atIndex:i+2];
            }
            [invocation invokeWithTarget:target];
            const char *returnType = signature.methodReturnType;
            if (strcmp(returnType, @encode(void))) {
                NSDictionary *returnData = nil;
                if (!strcmp(returnType, @encode(id))) {
                    void *temp;
                    [invocation getReturnValue:&temp];
                    id returnValue = (__bridge id)temp;
                    if ([returnValue isKindOfClass:NSString.class] || [returnValue isKindOfClass:NSValue.class]) {
                        returnData = @{k_type: k_base, k_value: returnValue};
                    } else {
                        _KSOCObject *returnObj = [_KSOCObject objectFromValue:returnValue];
                        NSString *key = [NSString stringWithFormat:k_location_format, returnValue];
                        @synchronized (tools.objectPoolLockToken) {
                            [objectPool setObject:returnObj forKey:key];
                        }
                        returnData = @{k_type: k_object, k_className: NSStringFromClass([returnValue class]), k_objKey: key};
                    }
                } else {
                    size_t length = signature.methodReturnLength;
                    NSNumber *value = __ks_numberFromInvocation(invocation, length, returnType);
                    if (value != nil) {
                        returnData = @{k_type: k_base, k_value: value};
                    } else {
                        void *buffer = (void *)malloc(length);
                        [invocation getReturnValue:buffer];
                        _KSOCObject *returnObj = [_KSOCObject locationFromValue:buffer];
                        NSString *key = [NSString stringWithFormat:k_location_format, buffer];
                        @synchronized (tools.objectPoolLockToken) {
                            [objectPool setObject:returnObj forKey:key];
                        }
                        returnData = @{k_type: k_other, k_objKey: key};
                    }
                }
                return returnData;
            }
        }
    }
    return nil;
}

+ (_KSOCMethodModel *)searchClass:(Class)class isClass:(BOOL)isclass method:(NSString *)methodString inCatalog:(NSMapTable <NSString *, _KSOCClassInfoModel*> *)catalog {
    _KSOCClassInfoModel *info = [catalog objectForKey:NSStringFromClass(class)];
    _KSOCMethodModel *model = isclass ? [info.classMethod objectForKey:methodString] : [info.instanceMethod objectForKey:methodString];
    if (model != nil) {
        return model;
    } else {
        return [self searchClass:[class superclass] isClass:isclass method:methodString inCatalog:catalog];
    }
}

+ (void)releaseObjects {
    KSOCObjectTools *tools = [KSOCObjectTools share];
    @synchronized (tools.objectPoolLockToken) {
        [tools.objectPool removeAllObjects];
    }
}

+ (NSString *)initJavaScriptString {
    return k_initJavaScriptString;
}

+ (NSDictionary<NSString *,KSWebViewScriptHandler *> *)scriptHandlers {
    static NSDictionary *k_scriptHandlers = nil;
    if (k_scriptHandlers == nil) {
        Class class = self.class;
        KSWebViewScriptHandler *importClass = [KSWebViewScriptHandler.alloc initWithTarget:class action:@selector(scriptHandlerImportClass:)];
        KSWebViewScriptHandler *invokeMethod = [KSWebViewScriptHandler.alloc initWithTarget:class action:@selector(scriptHandlerInvokeClassMethod:)];
        KSWebViewScriptHandler *releaseObjects = [KSWebViewScriptHandler.alloc initWithTarget:class action:@selector(releaseObjects)];
        k_scriptHandlers = @{@"__ks_importClass": importClass, @"__ks_invokeMethod": invokeMethod, @"__ks_releaseObjects": releaseObjects};
    }
    return k_scriptHandlers;
}

- (NSMapTable<NSString *, _KSOCClassInfoModel*> *)catalog {
    if (_catalog == nil) {
        _catalog = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _catalog;
}

- (NSMapTable<NSString *,_KSOCObject*> *)objectPool {
    if (_objectPool == nil) {
        _objectPool = [NSMapTable strongToStrongObjectsMapTable];
    }
    return _objectPool;
}

- (NSString *)catalogLockToken {
    if (_catalogLockToken == nil) {
        _catalogLockToken = [NSString stringWithFormat:@"catalogLockToken"];
    }
    return _catalogLockToken;
}

- (NSString *)objectPoolLockToken {
    if (_objectPoolLockToken == nil) {
        _objectPoolLockToken = [NSString stringWithFormat:@"objectPoolLockToken"];
    }
    return _objectPoolLockToken;
}

@end
