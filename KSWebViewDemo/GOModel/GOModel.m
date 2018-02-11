//
//  GOModel.m
//  MJExtensionExample
//
//  Created by nia_wei on 14-12-18.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "GOModel.h"

@implementation GOModel

/**
 *  归档实现
 */
MJCodingImplementation

+ (id)loadFromFile:(NSString *)path {
    id obj = nil;
    @try {
        obj = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    }
    @catch (NSException *exception) {
        obj = nil;
        NSLog(@"Exception : %@", exception);
    }
    @finally {
        
    }
    return obj;
}

- (BOOL)saveToFile:(NSString *)path {
    return [NSKeyedArchiver archiveRootObject:self toFile:path];
}

+ (id)loadFromData:(NSData *)data {
    id obj = nil;
    @try {
        obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception) {
        obj = nil;
        NSLog(@"Exception : %@", exception);
    }
    @finally {
        
    }
    return obj;
}

- (NSData *)dataFromModel {
    id obj = nil;
    @try {
        obj = [NSKeyedArchiver archivedDataWithRootObject:self];
    }
    @catch (NSException *exception) {
        obj = nil;
        NSLog(@"Exception : %@", exception);
    }
    @finally {
        
    }
    return obj;
}

#pragma mark @protocol MJKeyValue
+ (NSDictionary *)replacedKeyFromPropertyName {
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"id", @"base_id",
                            @"description", @"base_description", nil];
    return result;
}

//- (NSString *)description {
//    
//    return [[self keyValues] description];
//}

+ (NSMutableArray *)objectArrayWithKeyValuesArray:(NSArray *)keyValuesArray {
    return [self mj_objectArrayWithKeyValuesArray:keyValuesArray];
}

+ (instancetype)objectWithKeyValues:(id)keyValues {
    return [self mj_objectWithKeyValues:keyValues];
}

- (id)keyValues {
    return [self mj_keyValues];
}

@end
