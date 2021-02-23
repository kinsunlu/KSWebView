# 欢迎使用 KSWebView

pod 安装方式：
pod 'KSWebView'

如有问题欢迎加入QQ群：700276016

------

### KSWebView更新2.0啦，经过2年后我终于想起来要更新了，实在抱歉。。。。
### 本次更新重写大部分逻辑，优化js与原生的调用方式更直观，监听更加人性化。欢迎大家提宝贵意见

**KSWebView**是基于**WKWebview**进行2次封装的WebView。 KSWebView具有：

> * 用JS语句的方式调用原生类/对象，方便快捷，老板提出来的临时需求也能马上解决的方式。
> * 无缝JS与原生交互 (原生与JS获得各自的Return值) (一句语句注册JS方法调用回调)
> * 无缝JS与原生数据交互 丢弃cookie,数据由自己自由的管理,而且与原生互通。
> * 本地数据存储模块支持KVO,当数值发生变化时,注册了该值的观察者无论原生还是JS端都可以收到更新回调

### KSWebView的整体结构如下图
![KSWebView-class](https://raw.githubusercontent.com/kinsunlu/KSWebView/master/KSWebView.png)

------

## 用JS语句的方式调用原生类/对象
#### 例如我们想要在JS中执行下列OC代码
##### Objective-C:
```Objective-C
UIViewController *vc = [[UIViewController alloc]init];
[vc setTitle:@"测试标题"];

UIColor *whiteColor = [UIColor whiteColor];
[[vc view] setBackgroundColor:whiteColor];

[[vc view] setTag:17287];

UINavigationController *nav = [[[UIApplication sharedApplication] keyWindow] rootViewController];
[nav pushViewController:vc animated:YES];
```
##### JavaScript:
```JavaScript
//先导入要用到的OC类
var tools = window.OCTools;
var UIViewController = tools.importClass("UIViewController");
var UIColor = tools.importClass("UIColor");
var UIApplication = tools.importClass("UIApplication");

var vc = UIViewController.alloc().init();
vc.setTitle("测试标题");

var white = UIColor.whiteColor();
vc.view().setBackgroundColor(white);

vc.view().setTag(17287);

var nav = UIApplication.sharedApplication().keyWindow().rootViewController();
nav.pushViewControlleranimated(vc, true);
tools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
##### 是不是很简单？只要先导入要用到的类，然后就和用JS写一个OC代码一样简单！需要注意的是，调用多个参数的方法时需要去掉所有的冒号，然后将参数一次按顺序放入传参括号内，就可以了。例如：
##### Objective-C:
```Objective-C
UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"描述信息" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
[alert show];
```
##### JavaScript:
```JavaScript
var UIAlertView = window.OCTools.importClass("UIAlertView");
var alert = UIAlertView.alloc().initWithTitlemessagedelegatecancelButtonTitleotherButtonTitles("提示","描述信息",null,"关闭",null);
alert.show();
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
#### 返回值类型
##### 一切js可以识别的格式都是可以被js直接使用的(例如：string，number 等等).oc对象结构体等变量承接之后只可以当作方法传的值，因为js无法识别。这是必然，js是无法使用oc对象的。例如:
##### Objective-C:
```Objective-C
UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"描述信息" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
[alert setTag:15269];
[alert setTitle:@"新标题"];
NSInteger tag = [alert tag];
NSString *title = [alert title];
[alert show];
```
##### JavaScript:
```JavaScript
var UIAlertView = window.OCTools.importClass("UIAlertView");
var alert = UIAlertView.alloc().initWithTitlemessagedelegatecancelButtonTitleotherButtonTitles("提示","描述信息",null,"关闭",null);
alert.setTag(15269);
alert.setTitle("新标题");
var tag = alert.tag();//返回的number是可以直接使用的
var title = alert.title();//返回的string是可以直接使用的
alert.show();
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
#### Dictionary与Array
###### 快速的将JS对象转换为NSDictionary或将JS数组转换为NSArray
##### Dictionary:
```JavaScript
var data = {
'key': 'value',
'anyKey': 'anyValue'
};
//将JS对象转换为NSDictionary
var NSDictionary = window.OCTools.importClass("NSDictionary");
var dict = NSDictionary.dictionaryWithDictionary(data);
var KSHelper = window.OCTools.importClass("KSHelper");
//将NSDictionary转换为JS对象
var jsonString = KSHelper.jsonWithObject(dict);
var jsObject = JSON.parse(jsonString);
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
##### Array:
```JavaScript
var data = ["NO.1", "NO.2", "NO.3", "NO.4"];
//将JS对象转换为NSDictionary
var NSArray = window.OCTools.importClass("NSArray");
var arr = NSArray.arrayWithArray(data);
var KSHelper = window.OCTools.importClass("KSHelper");
//将NSDictionary转换为JS对象
var jsonString = KSHelper.jsonWithObject(arr);
var jsArray = JSON.parse(jsonString);
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
其实本质上JS的对象/数组可以直接当做NSDictionary/NSArray参数传递，上述只是提供了互相转换的方法。
##### ***importClass***:  该方法在内部已经实现了不管你重复import多少次相同的Class都拿到的是相同的一个，所以放心大胆的用，不用担心，不过最好将其放在界面加载完成后importClass，防止出现问题。
##### ***releaseObjects***: 因为内部对象都是有引用的所以只有调用了此方法才会销毁所有对象，如果长期不销毁内存会越来越大，严重就会导致崩溃，所以请尽量在使用完oc调用后调用此方法来销毁所有oc对象。
-----

## js调用原生交互
#### 更为直观的体现JS与原生的交互，打通js与原生之间的桥梁，实现无缝衔接。只要js的参数列表与原生相同那么就可以直接调用并互传参数与return值给js
##### 举例1
##### Objective-C注册:
```Objective-C

/// 可以return任意基本数据类型 或 NSString NSNumber NSArray NSDictionary
- (int)webViewScriptHandlerTestReturnValue {
    return 100;
}

KSWebViewScriptHandler *testReturnValue = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerTestReturnValue)];
NSDictionary *keyValues = @{@"testReturnValue":testReturnValue};
// 将keyValues 传递给KSWebView即可完成注册
```
##### JavaScript调用:
```JavaScript
var returnValue = window.android.testReturnValue();
// returnValue即为int形的100 支持所有基本数据类型和NSArray NSDictionary
```

##### 举例2
##### Objective-C注册:
```Objective-C

/// 可以return任意基本数据类型 或 NSString NSNumber NSArray NSDictionary
- (int)webViewScriptHandlerTestReturnValue {
    return 100;
}

- (void)webViewScriptHandlerAlertWithMessage:(NSNumber *)message {
    // 自动转换基本数据类型和NSNumber
}

KSWebViewScriptHandler *testReturnValue = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerTestReturnValue)];
KSWebViewScriptHandler *alert = [KSWebViewScriptHandler.alloc initWithTarget:self action:@selector(webViewScriptHandlerAlertWithMessage:)];
NSDictionary *keyValues = @{@"testReturnValue": testReturnValue, @"alert": alert};
// 将keyValues 传递给KSWebView即可完成注册
```
##### JavaScript调用:
```JavaScript
var returnValue = window.android.testReturnValue();
// returnValue即为int形的100 支持所有基本数据类型和NSArray NSDictionary
window.android.alert(returnValue);
```

## 本地数据存储模块与监听数据变化响应(KVO)
#### 有时候我们在开发过程中会遇到很多与webView交互的需求，例如：在Html中有一个文本，该文本是用来显示用户评论数的，在原生有一个工具栏上面也有个显示评论数的label，当用户增加一条评论的时候两个数字都要变化，这时候就很麻烦了，我们用cookie存储的东西客户端拿不到，客户端存储的东西js又不好获得，这就有了客户端与webview公用存储空间。我们可以在客户端开辟一块内存专门用来存放html与原生公用的数据，如果对其添加了监听KVO变化，我们就可以在原生与html都收到更新会掉从而各自更新自己的界面数据。
##### 那我们该如何使用这个存储模块呢？
###### 向存储模块设置一个值：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule.sharedModule setObject:@"qwertyuiop" forKey:@"token"];
```
##### JavaScript:
```JavaScript
var json = {'token': 'qwertyuiop'}
window.android.setValue(value, 'token');
```
###### 你还可以一次设置/更新多个值：
##### Objective-C:
```Objective-C
NSDictionary *dict = @{@"token": @"qwertyuiop", @"state": @"1"};
[KSWebDataStorageModule.sharedModule addEntriesFromDictionary:dict];
```
##### JavaScript:
```JavaScript
var map = {'token': 'qwertyuiop', "state": "1"}
window.android.setKeyValues(map);
```
###### 向存储模块索要一个值：
##### Objective-C:
```Objective-C
NSString *token = [KSWebDataStorageModule.sharedModule objectForKey:@"token"];
```
##### JavaScript:
```JavaScript
var token = window.android.getValue('token');
```
###### 对一个值添加监听者：
##### Objective-C:
```Objective-C

//和正常iOS添加兼听一样调用KSWebDataStorageModule.sharedModule 的-addObserver: forKeyPath: options: context: 并在-observeValueForKeyPath: ofObject: change: context: 接收回调即可

[KSWebDataStorageModule.sharedModule addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//变化后要执行的代码
}
```
##### JavaScript:
```JavaScript
//注意！observerCallback为方法名，本质是通过js调用了名称为observerCallback的方法，会回传两个值第一个为最新的值，第二个为更新前的值
window.android.addObserver('token', 'observerCallback');
```
ps.相同的webview如果多次注册一个值的监听的话是无效的只会回掉第一次注册的方法。
###### 对一个值移除监听者：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule.sharedModule removeObserver:self forKeyPath:@"token" context:nil];
```
##### JavaScript:
```JavaScript
window.android.removeObserver('token');
```
###### 移除所有值的监听者：
##### Objective-C:
```Objective-C
// 客户端暂不支持请调用如下方法
KSWebDataStorageModule *sharedModule = KSWebDataStorageModule.sharedModule;
for (NSString *key in keys) {
    [sharedModule removeObserver:self forKeyPath:key context:nil];
}
```
##### JavaScript:
```JavaScript
window.android.removeAllObserver();
```
###### 重置存储空间：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule.sharedModule removeAllObjects];
```
##### JavaScript:
```JavaScript
window.android.reinit();
```
！需要注意的是，这块存储空间是单利所以也可用于不同webview之间的传值，打通webview之间的联系。
## 更详细使用方法请查看demo
