//
//  SHCallManager.h
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHCallKitHeader.h"
#import "SHCallModel.h"

typedef enum : NSUInteger {
    SHCallPhoneState_None,//待机
    SHCallPhoneState_Out,//呼出
    SHCallPhoneState_In,//呼入
    SHCallPhoneState_Calling,//通话中
    SHCallPhoneState_Disconnect,//关闭
} SHCallPhoneState;

@protocol SHCallManagerDelegate <NSObject>

//状态回调
- (void)refreshCurrentCallStatus:(SHCallPhoneState)status;

@end

@interface SHCallManager : NSObject

//代理
@property (nonatomic, weak)  id<SHCallManagerDelegate>delegate;
//电话状态
@property (nonatomic, assign) SHCallPhoneState phoneState;
//通话时间
@property (nonatomic, strong) NSTimer *callTimer;
//通话日期格式
@property (nonatomic, strong) NSDateComponentsFormatter *formatter;
//通话模型
@property (nonatomic, strong) SHCallModel *callModel;
//是否正在拨打电话
@property (nonatomic, assign) BOOL isCalling;

#pragma mark - 初始化
+ (SHCallManager *)shareSHCallManager;

#pragma mark - 拨打方 呼出电话
- (void)starCallWithUserActivity:(NSUserActivity *)userActivity;

#pragma mark - 去电
- (void)startCallWithTelNum:(NSString *)telNum isVideo:(BOOL)isVideo;

#pragma mark - 来电
- (void)receiveCallWithTelNum:(NSString *)telNum;

#pragma mark - 挂电话
- (void)stopCall;

#pragma mark - 接电话
- (void)receiveCall;

@end
