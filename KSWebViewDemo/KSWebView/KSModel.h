//
//  KSModel.h
//  MJExtensionExample
//
//  Created by kinsun on 14-12-18.
//  Copyright (c) 2014年 kinsun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSModel : NSObject

/**
 *  将属性名换为其他key去字典中取值
 *
 *  @return 字典中的key是属性名，value是从字典中取值用的key
 */
+(NSDictionary*)replacedKeyFromPropertyName;

+(NSMutableArray*)objectArrayWithKeyValuesArray:(NSArray*)keyValuesArray;

+(instancetype)objectWithKeyValues:(id)keyValues;

-(id)keyValues;

@end
