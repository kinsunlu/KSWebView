//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#define k_id_type           @"@"
#define k_integer_type      @"integer"
#define k_double_type       @"double"
#define k_float_type        @"float"
#define k_CGRect_type       @"CGRect"
#define k_CGSize_type       @"CGSize"
#define k_CGPoint_type      @"CGPoint"
#define k_UIEdgeInsets_type @"UIEdgeInsets"

#define k_basic_data_key    @"basic_data"
#define k_object_name_key   @"object_name"
#define k_object_basic_key  @"object_basic"
#define k_model_key         @"model"

#import <Foundation/Foundation.h>

@interface KSReflectiveServiceObject : NSObject

@property (nonatomic, strong, readonly) id objectValue;
@property (nonatomic, assign, readonly) void *locationValue;
@property (nonatomic, assign, readonly) BOOL isObject;

+(instancetype)reflectiveServiceObjectValue:(id)objectValue;
+(instancetype)reflectiveServiceLocationValue:(void *)locationValue;

@end

@implementation KSReflectiveServiceObject

+(instancetype)reflectiveServiceObjectValue:(id)objectValue {
    KSReflectiveServiceObject *object = [[KSReflectiveServiceObject alloc]init];
    object->_objectValue = objectValue;
    object->_isObject = YES;
    return object;
}

+(instancetype)reflectiveServiceLocationValue:(void *)locationValue {
    KSReflectiveServiceObject *object = [[KSReflectiveServiceObject alloc]init];
    object->_locationValue = locationValue;
    object->_isObject = NO;
    return object;
}

-(void)dealloc {
    _objectValue = nil;
    _locationValue = NULL;
}

@end

#import <UIKit/UIKit.h>
#import "KSWebViewReflectiveService.h"

@implementation KSWebViewReflectiveServiceParamsModel
@synthesize model = _model;

-(id)model {
    if (!_model && [_data isKindOfClass:[NSString class]]) {
        NSString *modelJson = _data;
        NSString *modelClass = _modelClass;
        if (modelJson.length && modelClass.length) {
            Class class = NSClassFromString(modelClass);
            NSDictionary *dict = [modelJson mj_JSONObject];
            _model = [class objectWithKeyValues:dict];
        }
    }
    return _model;
}

-(void)argumentToInvocation:(NSInvocation*)invocation objectPool:(NSDictionary <NSString*,KSReflectiveServiceObject*>*)objectPool atIndex:(NSInteger)index {
    NSString *type = _type;
    void *argumentLocation = NULL;
    __unsafe_unretained id argumentValue = nil;
    if ([type isEqualToString:k_object_name_key]) {
        KSReflectiveServiceObject *obj = [objectPool valueForKey:_data];
        if (obj.isObject) {
            argumentValue = obj.objectValue;
        } else {
            argumentLocation = obj.locationValue;
        }
    } else if ([type isEqualToString:k_object_basic_key]) {
        id param = _data;
        if ([param isKindOfClass:[NSNull class]]) param = nil;
        argumentValue = param;
    } else if ([type isEqualToString:k_model_key]) {
        argumentValue = self.model;
    } else if ([type isEqualToString:k_basic_data_key]) {
        NSString *basicDataType = _basicDataType;
        if ([basicDataType isEqualToString:k_integer_type]) {
            NSInteger intNumber = [_data integerValue];
            argumentLocation = &intNumber;
        } else if ([basicDataType isEqualToString:k_double_type]) {
            double doubleNumber = [_data doubleValue];
            argumentLocation = &doubleNumber;
        } else if ([basicDataType isEqualToString:k_float_type]) {
            float floatNumber = [_data floatValue];
            argumentLocation = &floatNumber;
        } else if ([basicDataType isEqualToString:k_CGRect_type]) {
            CGRect rect = CGRectFromString(_data);
            argumentLocation = &rect;
        } else if ([basicDataType isEqualToString:k_CGPoint_type]) {
            CGPoint point = CGPointFromString(_data);
            argumentLocation = &point;
        } else if ([basicDataType isEqualToString:k_CGSize_type]) {
            CGSize size = CGSizeFromString(_data);
            argumentLocation = &size;
        } else if ([basicDataType isEqualToString:k_UIEdgeInsets_type]) {
            UIEdgeInsets edgeInsets = UIEdgeInsetsFromString(_data);
            argumentLocation = &edgeInsets;
        }
    }
    if (argumentValue) argumentLocation = &argumentValue;
    [invocation setArgument:argumentLocation atIndex:index];
}

@end

@implementation KSWebViewReflectiveServiceModel

+(NSDictionary *)objectClassInArray {
    return @{@"selectorParams":[KSWebViewReflectiveServiceParamsModel class]};
}

@end

@implementation KSWebViewReflectiveService

+(void)webViewReflectiveServiceWithSelf:(id)selfObj body:(NSString*)body {
    NSArray <NSDictionary*>*dict = [body mj_JSONObject];
    NSArray <KSWebViewReflectiveServiceModel*>*codes = [KSWebViewReflectiveServiceModel objectArrayWithKeyValuesArray:dict];
    
    KSReflectiveServiceObject *r_selfObj = [KSReflectiveServiceObject reflectiveServiceObjectValue:selfObj];
    NSMutableDictionary <NSString*,KSReflectiveServiceObject*>*objectPool = [NSMutableDictionary dictionaryWithObject:r_selfObj forKey:@"self"];
    [codes enumerateObjectsUsingBlock:^(KSWebViewReflectiveServiceModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        [self invocationSendMsgWithModel:model objectPool:objectPool];
    }];
}

+(void)invocationSendMsgWithModel:(KSWebViewReflectiveServiceModel*)model objectPool:(NSMutableDictionary*)objectPool {
    if (!model || !objectPool) return;
    NSString *instructionType = model.instructionType;
    NSString *objectName = model.objectName;
    if ([instructionType isEqualToString:@"add_object_to_pool"]) {
        NSArray <KSWebViewReflectiveServiceParamsModel*>*params = model.selectorParams;
        if (params.count) {
            KSWebViewReflectiveServiceParamsModel *param = params.firstObject;
            id data = param.data;
            if (data && [param.type isEqualToString:k_object_basic_key]) {
                KSReflectiveServiceObject *object = [KSReflectiveServiceObject reflectiveServiceObjectValue:data];
                [objectPool setObject:object forKey:objectName];
            }
        }
    } else {
        SEL selector = NSSelectorFromString(model.selectorString);
        id target = nil;
        NSMethodSignature *signature = nil;
        if ([instructionType isEqualToString:@"class_selector"]) {
            Class class = NSClassFromString(model.className);
            signature = [class methodSignatureForSelector:selector];
            target = class;
        } else if ([instructionType isEqualToString:@"obj_selector"]) {
            KSReflectiveServiceObject *obj = [objectPool objectForKey:objectName];
            id objectValue = obj.objectValue;
            if (objectValue) {
                signature = [[objectValue class] instanceMethodSignatureForSelector:selector];
                target = objectValue;
            }
        }
        if (signature && target) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.selector = selector;
            NSArray <KSWebViewReflectiveServiceParamsModel*>*params = model.selectorParams;
            if (params.count) {
                for (NSInteger i = 0; i<params.count; i++) {
                    KSWebViewReflectiveServiceParamsModel *paramsModel = [params objectAtIndex:i];
                    [paramsModel argumentToInvocation:invocation objectPool:objectPool atIndex:i+2];
                }
                [invocation retainArguments];
            }
            [invocation invokeWithTarget:target];
            NSString *selectorReturnValueName = model.selectorReturnValueName;
            if (selectorReturnValueName.length) {
                const char *returnType = signature.methodReturnType;
                if (strcmp(returnType, @encode(void))) {
                    KSReflectiveServiceObject *returnObj = nil;
                    if (!strcmp(returnType, @encode(id))) {
                        __unsafe_unretained id returnValue = nil;
                        [invocation getReturnValue:&returnValue];
                        returnObj = [KSReflectiveServiceObject reflectiveServiceObjectValue:returnValue];
                    } else {
                        NSUInteger length = signature.methodReturnLength;
                        void *buffer = (void *)malloc(length);
                        [invocation getReturnValue:buffer];
                        returnObj = [KSReflectiveServiceObject reflectiveServiceLocationValue:buffer];
                    }
                    if (returnObj) {
                        [objectPool setObject:returnObj forKey:selectorReturnValueName];
                    }
                }
            }
        }
    }
}

@end
