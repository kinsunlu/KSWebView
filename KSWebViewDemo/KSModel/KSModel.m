//
//  KSModel.m
//  MJExtensionExample
//
//  Created by kinsun on 14-12-18.
//  Copyright (c) 2014年 kinsun. All rights reserved.
//

#import "KSModel.h"
#import "MJExtension.h"

@implementation KSModel

#pragma mark @protocol MJKeyValue
+(NSDictionary *)replacedKeyFromPropertyName {
    return [NSDictionary dictionaryWithObjectsAndKeys:@"id", @"base_id", @"description", @"base_description", nil];
}

+(NSMutableArray*)objectArrayWithKeyValuesArray:(NSArray *)keyValuesArray {
    return [self mj_objectArrayWithKeyValuesArray:keyValuesArray];
}

+(instancetype)objectWithKeyValues:(id)keyValues {
    return [self mj_objectWithKeyValues:keyValues];
}

-(id)keyValues {
    return [self mj_keyValues];
}

@end
