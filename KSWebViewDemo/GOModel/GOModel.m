//
//  GOModel.m
//  MJExtensionExample
//
//  Created by nia_wei on 14-12-18.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "GOModel.h"

@implementation GOModel

- (NSString *)keyValuesjson {
    NSDictionary *obj = [self keyValues];
    return [obj JSONRepresentation];
}

#pragma mark @protocol MJKeyValue
+ (NSDictionary *)replacedKeyFromPropertyName {
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"id", @"base_id",
                            @"description", @"base_description", nil];
    return result;
}

@end
