# 欢迎使用 KSWebView

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
####例如我们想要在JS中执行下列OC代码
#####Objective-C:
```Objective-C
UIViewController *vc = [[UIViewController alloc]init];
[vc setTitle:@"测试标题"];

UIColor *whiteColor = [UIColor whiteColor];
[[vc view] setBackgroundColor:whiteColor];

[[vc view] setTag:17287];

UINavigationController *nav = [[[UIApplication sharedApplication] keyWindow] rootViewController];
[nav pushViewController:vc animated:YES];
```
#####JavaScript:
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
#####是不是很简单？只要先导入要用到的类，然后就和用JS写一个OC代码一样简单！需要注意的是，调用多个参数的方法时需要去掉所有的冒号，然后将参数一次按顺序放入传参括号内，就可以了例如：
#####Objective-C:
```Objective-C
UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"描述信息" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
[alert show];
```
#####JavaScript:
```JavaScript
var UIAlertView = window.OCTools.importClass("UIAlertView");
var alert = UIAlertView.alloc().initWithTitlemessagedelegatecancelButtonTitleotherButtonTitles("提示","描述信息",null,"关闭",null);
alert.show();
window.OCTools.releaseObjects();//调用完毕后为了防止内存溢出必须释放
```
#### 返回值类型
##### 一切js可以识别的格式都是可以被js直接使用的(例如：string，numer 等等).oc对象结构体等变量承接之后只可以当作方法传的值，因为js无法识别。这是必然，js是无法使用oc对象的。例如:
#####Objective-C:
```Objective-C
UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"描述信息" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
[alert setTag:15269];
[alert setTitle:@"新标题"];
NSInteger tag = [alert tag];
NSString *title = [alert title];
[alert show];
```
#####JavaScript:
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
###### Dictionary:
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
###### Array:
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
##### ***releaseObjects***: 因为内部对象都是有引用的所以只有调用了此方法才会销毁所有对象，如果长期被销毁内存会越来越大，严重就会导致崩溃，所以请尽量在使用完oc调用后调用此方法来销毁所有oc对象。

## 无缝JS与原生交互/本地数据存储模块支持KVO请查看demo
