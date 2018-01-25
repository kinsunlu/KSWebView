//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

/* 此类为webView反射类,就是用JS模拟原生的代码以便发版之后用JS控制原生界面或者其他的一些指针.
 * 主要就是传一段json,json内容示例请看test.html中的实现.
 * 此方法的缺点为无法调用for if 等指令只能实现简单的操作
 * KSMainViewController中有json生成示例
 *
 * ServiceParamsModel及ServiceModel暴露出的所有属性均在原生中没什么作用,一般情况下都是用来生成json用的,由于后端也不太懂iOS反射实现逻辑
 * 所以一般都是由我们写一些模型然后将其生成json再交给服务端,此类一般涌来应急不建议直接当作实现,等新版本发布后还是建议改为使用原生方式控制原生界面元素
 */

#define k_CallReflection @"callReflection"

#import "GOModel.h"

/*
 * KSWebViewReflectiveServiceParamsModel为方法参数类
 */
@interface KSWebViewReflectiveServiceParamsModel : GOModel

/* @type
 * 参数类型分为4种
 * 1.basic_data 基本数据类型,设置此项时必须设置 basicDataType及data(数据)
 * 2.model 本地已经定义过的模型类型,设置此项时必须设置modelClass及data(存放模型json)
 * 3.object_basic 对象型基本数据,设置此项时必须设置data(number,string等);
 * 4.object_name 某方法的返回值对象,这个类型不是服务器返回的,而是我们调用某些方法之后用一个名称承接的,方法的参数可直接使用其名称
 */
@property (nonatomic, copy) NSString *type;

//model//object_name//object_basic
@property (nonatomic, strong) id data;

//model
@property (nonatomic, strong) NSString *modelClass;//模型的类型
@property (nonatomic, strong, readonly) id model;

//type为basic_data时需要设置此项为以下项目,CG开头的设置CG***FromString的参数类型
//CGRect//CGPoint//CGSize//UIEdgeInsets//integer//double//float
@property (nonatomic, copy) NSString *basicDataType;

@end

/*
* KSWebViewReflectiveServiceModel为方法调用类
*/
@interface KSWebViewReflectiveServiceModel : GOModel

/* @instructionType 调用方法的类型
 * 1.add_object_to_pool 将一个字符串或者number直接加入
 * 2.class_selector 调用类方法 必须填写className及selectorString
 * 3.obj_selector 调用实例方法 必须填写objectName及selectorString
 */
@property (nonatomic, copy) NSString *instructionType;
//调用对象的key
@property (nonatomic, copy) NSString *objectName;
//类方法的类名字符串
@property (nonatomic, copy) NSString *className;

//方法名例如"alloc","initWithFrame:"
@property (nonatomic, copy) NSString *selectorString;
//参数对象,为了应对多参数而准备的,按参数顺序填写参数
@property (nonatomic, strong) NSArray <KSWebViewReflectiveServiceParamsModel*>*selectorParams;
//接受函数调用之后的返回值的key
@property (nonatomic, copy) NSString *selectorReturnValueName;

@end

#import <Foundation/Foundation.h>

@interface KSWebViewReflectiveService : NSObject

+(void)webViewReflectiveServiceWithSelf:(id)selfObj body:(NSString*)body;

@end
