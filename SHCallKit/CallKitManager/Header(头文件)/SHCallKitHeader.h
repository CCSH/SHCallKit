//
//  SHCallKitHeader.h
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#ifndef SHCallKitHeader_h
#define SHCallKitHeader_h


#endif /* SHCallKitHeader_h */

#define Use_CallKit IOS(10)

#define IOS(V) [[[UIDevice currentDevice] systemVersion] doubleValue] >= V

//typedef enum : NSUInteger {
//    SHCallPhoneState_Out,//呼出
//    SHCallPhoneState_In,//呼入
//    SHCallPhoneState_Calling,//通话中
//    SHCallPhoneState_Fail,//失败
//    SHCallPhoneState_Disconnect,//关闭
//    SHCallPhoneState_Connected,//成功
//} SHCallPhoneState;

// Phone commands
typedef NS_ENUM(UInt32, ASPhoneCommandType) {
    //Command
    ASPhoneCommandTypeRefuse      = 0x01, //
    ASPhoneCommandTypeAccept   = 0x2, //
    ASPhoneCommandTypeData   = 0x03, //
};


//weakself
#define WeakSelf __weak typeof(self) weakSelf = self;

//通知
//通话状态通知
//#define Not_phoneState @"Not_phoneState"


//类
#import "SHCallManager.h"
#import "SHCallModel.h"
