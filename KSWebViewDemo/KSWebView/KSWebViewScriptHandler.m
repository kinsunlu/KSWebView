//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSWebViewScriptHandler.h"

@implementation KSWebViewScriptHandler {
    SEL _action;
}

-(void)setAction:(SEL)action {
    _action = action;
}

-(SEL)action {
    return _action;
}

-(instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super init]) {
        _target = target;
        _action = action;
    }
    return self;
}

+(KSWebViewScriptHandler*)scriptHandlerWithTarget:(id)target action:(SEL)action {
    return [[self alloc]initWithTarget:target action:action];
}

@end
