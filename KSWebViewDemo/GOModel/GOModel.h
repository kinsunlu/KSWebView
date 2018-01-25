//
//  GOModel.h
//  MJExtensionExample
//
//  Created by nia_wei on 14-12-18.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"
#import "NSObject+SBJson.h"

@interface GOModel : NSObject

/**
 *  将属性名换为其他key去字典中取值
 *
 *  @return 字典中的key是属性名，value是从字典中取值用的key
 */
+ (NSDictionary *)replacedKeyFromPropertyName;

@end
