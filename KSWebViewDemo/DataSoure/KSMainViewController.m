//
//  KSMainViewController.m
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#import "KSMainViewController.h"

@interface KSMainViewController ()

@end

@implementation KSMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KSWebViewScriptHandler *testJSCallback  = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerTestJSCallbackWithMessage:)];
    KSWebViewScriptHandler *testReturnValue = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerTestReturnValue)];
    KSWebViewScriptHandler *alert           = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerAlertWithMessage:)];
    KSWebViewScriptHandler *openNewPage     = [KSWebViewScriptHandler scriptHandlerWithTarget:self action:@selector(webViewScriptHandlerOpenNewPage)];
    self.webView.scriptHandlers = @{@"testJSCallback" :testJSCallback,
                                    @"testReturnValue":testReturnValue,
                                    @"alert"          :alert,
                                    @"openNewPage"    :openNewPage};
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    self.filePath = path;
    [self loadWebView];
    
    /*
    //以下是反射json生成示例---创建一个背景色为红色的空白view并加入到当前view
    //id view = [UIView alloc];
    KSWebViewReflectiveServiceModel *model1 = [[KSWebViewReflectiveServiceModel alloc]init];
    model1.instructionType = @"class_selector";
    model1.className = @"UIView";
    model1.selectorString = @"alloc";
    model1.selectorReturnValueName = @"view";
    
    //[view initWithFrame:(CGRect){200,200,200,200}];
    KSWebViewReflectiveServiceModel *model2 = [[KSWebViewReflectiveServiceModel alloc]init];
    model2.instructionType = @"obj_selector";
    model2.objectName = @"view";
    model2.selectorString = @"initWithFrame:";
    //设置frame参数
    KSWebViewReflectiveServiceParamsModel *param1 = [[KSWebViewReflectiveServiceParamsModel alloc]init];
    param1.type = @"basic_data";
    param1.basicDataType = @"CGRect";
    param1.data = @"{{200,200},{200,200}}";
    model2.selectorParams = @[param1];
    
    //生成一个红色的UIColor为背景色做准备
    //UIColor *redColor = [UIColor redColor];
    KSWebViewReflectiveServiceModel *model3 = [[KSWebViewReflectiveServiceModel alloc]init];
    model3.instructionType = @"class_selector";
    model3.className = @"UIColor";
    model3.selectorString = @"redColor";
    model3.selectorReturnValueName = @"redColor";
    
    //[view setBackgroundColor:redColor];
    KSWebViewReflectiveServiceModel *model4 = [[KSWebViewReflectiveServiceModel alloc]init];
    model4.instructionType = @"obj_selector";
    model4.objectName = @"view";
    model4.selectorString = @"setBackgroundColor:";
    //设置frame参数
    KSWebViewReflectiveServiceParamsModel *param2 = [[KSWebViewReflectiveServiceParamsModel alloc]init];
    param2.type = @"object_name";
    param2.data = @"redColor";
    model4.selectorParams = @[param2];
    
    //每个反射都会自带一个key为self的对象就示例当前控制器或者为你注册方法时传过去的对象
    //取self.view
    KSWebViewReflectiveServiceModel *model5 = [[KSWebViewReflectiveServiceModel alloc]init];
    model5.instructionType = @"obj_selector";
    model5.objectName = @"self";
    model5.selectorString = @"view";
    model5.selectorReturnValueName = @"selfView";
    
    //[selfView addSubview:view];
    KSWebViewReflectiveServiceModel *model6 = [[KSWebViewReflectiveServiceModel alloc]init];
    model6.instructionType = @"obj_selector";
    model6.objectName = @"selfView";
    model6.selectorString = @"addSubview:";
    KSWebViewReflectiveServiceParamsModel *param3 = [[KSWebViewReflectiveServiceParamsModel alloc]init];
    param3.type = @"object_name";
    param3.data = @"view";
    model6.selectorParams = @[param3];
    
    NSArray *modelArray = @[model1,model2,model3,model4,model5,model6];
    
    //将模型数组转换为字典数组
    NSArray *array = [KSWebViewReflectiveServiceModel keyValuesArrayWithObjectArray:modelArray];
    //将字典数组转换为json就可以了,将json发送给H5让他调用时当作参数就OK了
    NSString *json = [array JSONRepresentation];
    */
}

-(void)layoutWebView:(KSWebView *)webView {
    [super layoutWebView:webView];
    UIScrollView *scrollView = webView.scrollView;
    CGFloat top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    scrollView.contentInset = (UIEdgeInsets){top,0.f,0.f,0.f};//复杂的Html中不建议设置此项会影响布局
}

-(void)webViewScriptHandlerTestJSCallbackWithMessage:(WKScriptMessage*)message {
    NSLog(@"JS调用了客户端的方法!");
}

//return的值 务必转成String
-(NSString*)webViewScriptHandlerTestReturnValue {
    return @"拿到客户端反回的值啦!!";
}

-(void)webViewScriptHandlerAlertWithMessage:(WKScriptMessage*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"来自网页的信息" message:message.body preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)webViewScriptHandlerOpenNewPage {
    KSMainViewController *controller = [[KSMainViewController alloc]init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
