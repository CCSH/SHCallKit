//
//  SHCallManager.m
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "SHCallManager.h"
#import <CallKit/CallKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Intents/Intents.h>
#import <UIKit/UIKit.h>


@interface SHCallManager ()<CXProviderDelegate,CXCallObserverDelegate>

//管理器
@property (nonatomic, strong) CXProvider *provider;
//call 界面
@property (nonatomic, strong) CXCallController *callController;
//当前用户ID
@property (nonatomic, strong) NSUUID *currentUUID;

@end

@implementation SHCallManager

+ (SHCallManager *)shareSHCallManager{
    
    static SHCallManager *callManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        callManager = [[SHCallManager alloc]init];
        [callManager setup];
    });
    
    return callManager;
}

#pragma mark - 配置参数
- (void)setup{
    
    //配置其他信息
    [self provider];
    [self callController];
}

#pragma mark - 去电
- (void)startCallWithTelNum:(NSString *)telNum isVideo:(BOOL)isVideo{
    
    self.isCalling = YES;
    //初始化模型
    self.callModel = [[SHCallModel alloc]init];
    self.callModel.telNum = telNum;
    self.callModel.userName = telNum;
    self.callModel.time = [NSDate date];
    
    self.currentUUID = [NSUUID UUID];

#ifdef Use_CallKit
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:telNum];
    CXStartCallAction *action = [[CXStartCallAction alloc]initWithCallUUID:self.currentUUID handle:handle];
    action.video = isVideo;
    CXTransaction *transaction = [[CXTransaction alloc]init];
    [transaction addAction:action];
    
    //提交给系统
    [self requestTransaction:transaction];
#else
    //原有逻辑

#endif
}

#pragma mark - 来电
- (void)receiveCallWithTelNum:(NSString *)telNum{

#ifdef Use_CallKit
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:telNum];
    callUpdate.remoteHandle = handle;
    callUpdate.localizedCallerName = telNum;
    //是否支持键盘拨号
    callUpdate.supportsDTMF = NO;
    //通话过程中再来电，是否支持保留并接听
    callUpdate.supportsHolding = NO;
    //本次通话是否有视频
    callUpdate.hasVideo = NO;
    //是否支持多人
    callUpdate.supportsGrouping = NO;
    
    WeakSelf;
    [self.provider reportNewIncomingCallWithUUID:self.currentUUID update:callUpdate completion:^(NSError *error){
        
        if (!error){
            
            weakSelf.callModel = [[SHCallModel alloc]init];
            weakSelf.callModel.telNum = telNum;
            
        }else{
            
        }
    }];
#else
    //原有逻辑
    
#endif
}

#pragma mark - 挂电话
- (void)stopCall{
    
#ifdef Use_CallKit
    CXEndCallAction *action = [[CXEndCallAction alloc]initWithCallUUID:self.currentUUID];
    CXTransaction *transaction = [[CXTransaction alloc]init];
    [transaction addAction:action];
    [self requestTransaction:transaction];
#else
   //原有逻辑
    
#endif
}

#pragma mark - 接电话
-(void)receiveCall{
    

}

#pragma mark - 外部唤起进行拨打电话
- (void)starCallWithUserActivity:(NSUserActivity *)userActivity{
    
    INInteraction *interaction = userActivity.interaction;
    INIntent *intent = interaction.intent;
    
    if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"]){
        
        INPerson *person = [(INStartAudioCallIntent *)intent contacts][0];
        [self startCallWithTelNum:person.personHandle.value isVideo:NO];
        
    } else if([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        
        INPerson *person = [(INStartVideoCallIntent *)intent contacts][0];
        [self startCallWithTelNum:person.personHandle.value isVideo:YES];
    }
}

#pragma mark - mainPrivate
//无论何种操作都需要 话务控制器 去 提交请求 给系统
- (void)requestTransaction:(CXTransaction *)transaction{
    
    [self.callController requestTransaction:transaction completion:^( NSError *_Nullable error){
        
        if (error !=nil) {
            
            NSLog(@"Error requesting transaction:\n%@", error.description);
        }else{
            NSLog(@"Requested transaction successfully");
        }
    }];
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider  {
    NSLog(@"CK: Provider did reset");
    NSLog(@"resetedUUID:%ld",provider.pendingTransactions.count);
}

#pragma mark 创建成功
- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"CK: Provider did begin");
}

#pragma mark 返回true 不执行系统通话界面 直接End
- (BOOL)provider:(CXProvider *)provider executeTransaction:(CXTransaction *)transaction {
    NSLog(@"CK: Provider execute transaction");
    return NO;
}

#pragma mark 当拨打方成功发起一个通话后，会触发
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"CK: Start Call Action");
    
    NSUUID *currentID = self.currentUUID;
    
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        
        //可以建立回调接收状态
        
        //原有逻辑
        
        [action fulfill];
    } else {
        [action fail];
    }
}

#pragma mark 当接听方成功接听一个电话时，会触发
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"CK: Answer Call Action");
    //接听电话
    [self receiveCall];
    [action fulfill];
}

#pragma mark 当接听方拒接电话或者双方结束通话时，会触发
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"CK: End Call Action");
    NSUUID *currentID = self.currentUUID;
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        //挂电话
        [self stopCall];
        [action fulfill];
    } else {
        [action fail];
    }
}

#pragma mark 当点击系统通话界面的Mute按钮时，会触发
- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    NSLog(@"CallKit---- %@",action.muted?@"通话静音":@"通话取消静音");
    [action fulfill];
}

#pragma mark 群组通话
- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action {
    NSLog(@"CK: Set Group Call Action");
    [action fulfill];
}

#pragma mark 双音频功能
- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
    NSLog(@"CK: Play DTMF Call Action");
    [action fulfill];
}

#pragma mark 通话保留
- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
    NSLog(@"CK: Set Held Call Action");
    [action fulfill];
    NSLog(@"CallKit----%@",(action.onHold)?@"通话保留":(@"恢复通话"));
}

/// Called when an action was not performed in time and has been inherently failed. Depending on the action, this timeout may also force the call to end. An action that has already timed out should not be fulfilled or failed by the provider delegate
#pragma mark 连接超时
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"CK: Provider Timed out");
}

/// Called when the provider's audio session activation state changes.
#pragma mark audio session 设置
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    //音频开始
    
    NSLog(@"CK: Audio session activated");
}

#pragma mark 通话结束音频处理
- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"CK: Audio session deactivated");
}

#pragma mark - CXCallObserverDelegate
- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call{
    
    NSLog(@"CallKit\ncallObserver---%ld\ncall.isOnHold---%d\ncall.isOutgoing---%d\ncall.hasConnected---%d\ncall.hasEnded---%d",callObserver.calls.count,call.isOnHold,call.isOutgoing,call.hasConnected,call.hasEnded);
    
    if (self.currentUUID){
        
        if ([call.UUID.UUIDString isEqualToString:self.currentUUID.UUIDString]) {
            //当前通话
            if (call.hasEnded) {
                NSLog(@"通话结束");
            }
            
            if (call.isOutgoing) {
                NSLog(@"正在呼出会话");
            }
            
            if (call.isOnHold) {
                NSLog(@"保留通话");
            }
            
        }
    }
}

#pragma mark - 懒加载
- (CXCallController *)callController{
    if (!_callController) {
        _callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
        [_callController.callObserver setDelegate:self queue:nil];
    }
    return _callController;
}

- (CXProvider *)provider{
    
    if (!_provider) {
        
        //系统来电页面显示的app名称和系统通讯记录的信息
        CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"SHCall"];
        //支持的Handle类型 不加这一行 系统电话号码长按不会出现当前app的名字（坑） 也可以支持邮件 根据app的功能来选
        config.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
        //锁屏接听时，系统界面右下角的app图标，要求40 x 40大小
        UIImage *icon = [UIImage imageNamed:@"icon"];
        config.iconTemplateImageData = UIImagePNGRepresentation(icon);
        //来电铃声
        config.ringtoneSound = @"Ringtone.caf";
        //是否支持视频
        config.supportsVideo = YES;
        //最大通话组
        config.maximumCallsPerCallGroup = 1;
        config.maximumCallGroups = 1;
        
        _provider = [[CXProvider alloc]initWithConfiguration:config];
        [_provider setDelegate:self queue:nil];
    }
    return _provider;
}

- (NSDateComponentsFormatter *)formatter{
    
    if (!_formatter) {
        _formatter = [[NSDateComponentsFormatter alloc] init];
        _formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        _formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
        _formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    }
    
    return _formatter;
}

#pragma mark - Set
- (void)setPhoneState:(SHCallPhoneState)phoneState{
    
    if (_phoneState == phoneState) {
        return;
    }
    
    _phoneState = phoneState;
    
    //呼入
    if (phoneState == SHCallPhoneState_In) {
        
        self.callModel = [[SHCallModel alloc]init];
        self.callModel.telNum = @"1234567890";
        self.callModel.userName = @"abc";
        
        self.currentUUID = [NSUUID UUID];
    }
    
    //通话中
    if (phoneState == SHCallPhoneState_Calling) {
        self.callModel.time = [NSDate date];
    }

    //代理回调
    if ([self.delegate respondsToSelector:@selector(refreshCurrentCallStatus:)]) {
        [self.delegate refreshCurrentCallStatus:phoneState];
    }

#ifdef Use_CallKit
    
    //呼出
    if (phoneState == SHCallPhoneState_Out) {
        
        [self.provider reportOutgoingCallWithUUID:self.currentUUID startedConnectingAtDate:self.callModel.time];
    }
    
    //待机
    if (phoneState == SHCallPhoneState_None) {
        
        [self.provider reportOutgoingCallWithUUID:self.currentUUID connectedAtDate:[NSDate date]];
    }
    
    if (phoneState == SHCallPhoneState_Out || phoneState == SHCallPhoneState_In){
        //结束
        [self stopCall];
    }
    
#else
    //原有逻辑

#endif

}

#pragma mark - 初始化数据
- (void)reloadData{

    if (self.currentUUID) {
        self.currentUUID = nil;
    }
}

@end
