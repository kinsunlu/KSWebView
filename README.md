# 欢迎使用 KSWebView

pod 安装方式：
pod 'KSWebView'

如有问题欢迎加入QQ群：700276016

------

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
//将NSDictionary转换为JS对象
var jsonString = dict.mj_JSONString();
var jsObject = JSON.parse(jsonString);
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
##### Array:
```JavaScript
var data = ["NO.1", "NO.2", "NO.3", "NO.4"];
//将JS对象转换为NSDictionary
var NSArray = window.OCTools.importClass("NSArray");
var arr = NSArray.arrayWithArray(data);
//将NSDictionary转换为JS对象
var jsonString = arr.mj_JSONString();
var jsArray = JSON.parse(jsonString);
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
其实本质上JS的对象/数组可以直接当做NSDictionary/NSArray参数传递，上述只是提供了互相转换的方法。
##### ***importClass***:  该方法在内部已经实现了不管你重复import多少次相同的Class都拿到的是相同的一个，所以放心大胆的用，不用担心，不过最好将其放在界面加载完成后importClass，防止出现问题。
##### ***releaseObjects***: 因为内部对象都是有引用的所以只有调用了此方法才会销毁所有对象，如果长期不销毁内存会越来越大，严重就会导致崩溃，所以请尽量在使用完oc调用后调用此方法来销毁所有oc对象。
-----

## 本地数据存储模块与监听数据变化响应(KVO)
#### 有时候我们在开发过程中会遇到很多与webView交互的需求，例如：在Html中有一个文本，该文本是用来显示用户评论数的，在原生有一个工具栏上面也有个显示评论数的label，当用户增加一条评论的时候两个数字都要变化，这时候就很麻烦了，我们用cookie存储的东西客户端拿不到，客户端存储的东西js又不好获得，这就有了客户端与webview公用存储空间。我们可以在客户端开辟一块内存专门用来存放html与原生公用的数据，如果对其添加了监听KVO变化，我们就可以在原生与html都收到更新会掉从而各自更新自己的界面数据。
##### 那我们该如何使用这个存储模块呢？
###### 向存储模块设置一个值：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule setValue:@"qwertyuiop" forKey:@"token"];
```
##### JavaScript:
```JavaScript
var json = {'token': 'qwertyuiop'}
window.control.call('setValue',JSON.stringify(json));
```
###### 你还可以一次设置/更新多个值：
##### Objective-C:
```Objective-C
NSDictionary *dict = @{@"token": @"qwertyuiop", @"state": @"1"};
[KSWebDataStorageModule setKeyValueDictionary:dict];
```
##### JavaScript:
```JavaScript
var json = {'token': 'qwertyuiop', "state": "1"}
window.control.call('setValue',JSON.stringify(json));
```
###### 向存储模块索要一个值：
##### Objective-C:
```Objective-C
NSString *token = [KSWebDataStorageModule valueForKey:@"token"];
```
##### JavaScript:
```JavaScript
var token = window.control.call('getValue','token');
```
###### 对一个值添加监听者：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule addObserver:self callback:^(NSString *value, NSString *oldValue) {
//变化后要执行的代码
} forKeyPath:@"token"];
```
##### JavaScript:
```JavaScript
//注意！observerCallback为方法名，本质是通过js调用了名称为observerCallback的方法，会回传两个值第一个为最新的值，第二个为更新前的值
var json = {'token': 'observerCallback'};
window.control.call('addObserver',JSON.stringify(json));
```
ps.相同的webview如果多次注册一个值的监听的话是无效的只会回掉第一次注册的方法。
###### 对一个值移除监听者：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule removeObserver:self forKeyPath:@"token"];
```
##### JavaScript:
```JavaScript
window.control.call('removeObserver','token');
```
###### 移除所有值的监听者：
##### Objective-C:
```Objective-C
[KSWebDataStorageModule removeObserver:self];
```
##### JavaScript:
```JavaScript
window.control.call('removeCurrentObserver');
```
###### JS重置存储空间：
##### JavaScript:
```JavaScript
window.control.call('reInit');
```
！需要注意的是，这块存储空间是单利所以也可用于不同webview之间的传值，打通webview之间的联系。
## 更详细使用方法请查看demo
