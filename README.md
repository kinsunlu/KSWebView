# 欢迎使用 KSWebView

------

KSWebView是基于WKWebview进行2次封装的WebView。
KSWebVie具有：

> * 无缝JS与原生交互
(原生与JS获得各自的Return值)
(一句语句注册JS方法调用回调)
> * 无缝JS与原生数据交互
丢弃cookie,数据由自己自由的管理,而且与原生互通
> * 监听本地库中的数据
JS/原生注册了回调之后,每当数值发生了变化就会分别回调注册的方法
> * JS反射原生代码
写一段JSON就能执行任意oc代码语句

------

## 类图

![image](https://raw.githubusercontent.com/kinsunlu/KSWebView/master/KSWebView.png)

------
