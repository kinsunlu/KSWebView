//
//  KSWebViewDemo
//
//  Created by kinsun on 2018/1/22.
//  Copyright © 2018年 kinsun. All rights reserved.
//

#ifndef KSConstants_h
#define KSConstants_h

#define k_creatFrameElement  CGFloat viewX=0.f,viewY=0.f,viewW=0.f,viewH=0.f
#define k_setFrame           (CGRect){viewX,viewY,viewW,viewH}
#define k_settingFrame(view) (view).frame = k_setFrame

#define k_IOS_Version  [UIDevice currentDevice].systemVersion.floatValue


#endif /* KSConstants_h */
