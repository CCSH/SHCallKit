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

#pragma mark - 单例
+ (SHCallManager *)shareSHCallManager{
    
    static SHCallManager *callManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        callManager = [[SHCallManager alloc]init];
        [callManager setup];
    });
    
    return callManager;
}

#pragma mark 配置参数
- (void)setup{
    
    //配置其他信息
    [self provider];
    [self callController];
}

#pragma mark - 公共方法
#pragma mark 外部唤起进行拨打电话
- (void)starCallWithUserActivity:(NSUserActivity *)userActivity{
    
#ifdef Use_CallKit
    INInteraction *interaction = userActivity.interaction;
    INIntent *intent = interaction.intent;
    
    if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"]){//语音通话
        
        INPerson *person = [(INStartAudioCallIntent *)intent contacts][0];
        [self startCallWithTelNum:person.personHandle.value];
        
    } else if([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {//视频通话
        
        INPerson *person = [(INStartVideoCallIntent *)intent contacts][0];
        [self startCallWithTelNum:person.personHandle.value];
    }
#else
    //原有逻辑、外部唤起app拨打电话
    
#endif
}

#pragma mark 拨打电话
- (void)startCallWithTelNum:(NSString *)telNum{
    
    //号码存在判断
    if (!telNum.length) {
        return;
    }
    
    self.currentUUID = [NSUUID UUID];
    
    //初始化模型
    self.callModel = [[SHCallModel alloc]init];
    self.callModel.telNum = telNum;
    self.callModel.userName = telNum;
    self.callModel.time = [NSDate date];

#ifdef Use_CallKit
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:telNum];
    CXStartCallAction *action = [[CXStartCallAction alloc]initWithCallUUID:self.currentUUID handle:handle];
    action.video = NO;
    
    CXTransaction *transaction = [[CXTransaction alloc]init];
    [transaction addAction:action];

    //提交给系统
    [self requestTransaction:transaction];
#else
    //原有逻辑、去电
    [self old_startCallWithTelNum:self.callModel.telNum];

#endif
}

#pragma mark 接听电话
- (void)answerCallWithTelNum:(NSString *)telNum{
    
    //号码存在判断
    if (!telNum.length) {
        return;
    }
    
    self.currentUUID = [NSUUID UUID];
    //初始化模型
    self.callModel = [[SHCallModel alloc]init];
    self.callModel.telNum = telNum;
    self.callModel.userName = telNum;
    self.callModel.time = [NSDate date];

#ifdef Use_CallKit
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:telNum];
    callUpdate.remoteHandle = handle;
    callUpdate.localizedCallerName = telNum;
    //是否支持键盘拨号
    callUpdate.supportsDTMF = YES;
    //通话过程中再来电，是否支持保留并接听
    callUpdate.supportsHolding = NO;
    //本次通话是否有视频
    callUpdate.hasVideo = NO;
    //是否支持多人
    callUpdate.supportsGrouping = NO;
    
    [self.provider reportNewIncomingCallWithUUID:self.currentUUID update:callUpdate completion:^(NSError *error){
        
        if (!error){
            
        }else{
            
            NSLog(@"error:%@",error.description);
        }
    }];
#else
    //原有逻辑、来电
    
#endif
}

#pragma mark 挂断电话
- (void)stopCall{
    
#ifdef Use_CallKit
    CXEndCallAction *action = [[CXEndCallAction alloc]initWithCallUUID:self.currentUUID];
    CXTransaction *transaction = [[CXTransaction alloc]init];
    [transaction addAction:action];
    [self requestTransaction:transaction];
#else
   //原有逻辑、挂电话
    
#endif
}

#pragma mark - 原有逻辑
#pragma mark 拨打电话
- (void)old_startCallWithTelNum:(NSString *)telNum{
    
}

#pragma mark - 接听电话
- (void)old_answerCallWithTelNum:(NSString *)telNum{
    
}

#pragma mark - 挂断电话
- (void)old_stopCall{
    
}

#pragma mark 开启音频
- (void)openAudio{
    
}

#pragma mark 关闭音频
- (void)closeAudio{
    
}

#pragma mark 静音功能
- (void)isMute:(BOOL)mute{
    
}

#pragma mark 键盘点击
- (void)clickKeyboardWithDigits:(NSString *)digits{
    
}

#pragma mark - mainPrivate
//无论何种操作都需要 话务控制器 去 提交请求 给系统
- (void)requestTransaction:(CXTransaction *)transaction{
    
    [self.callController requestTransaction:transaction completion:^( NSError *_Nullable error){
        
        if (error != nil) {
            
            NSLog(@"Error requesting transaction:\n%@", error.description);
        }else{
            
            NSLog(@"Requested transaction successfully");
        }
    }];
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    NSLog(@"CK: Provider did reset");
    NSLog(@"resetedUUID:%ld",provider.pendingTransactions.count);
}

#pragma mark 创建成功
- (void)providerDidBegin:(CXProvider *)provider {
    NSLog(@"CK: 创建成功");
}

#pragma mark 返回YES 不执行系统操作 直接结束
- (BOOL)provider:(CXProvider *)provider executeTransaction:(CXTransaction *)transaction {
    NSLog(@"CK: 操作成功");
    return NO;
}

#pragma mark 拨打电话
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    NSLog(@"CK: 拨打电话");
    
    NSUUID *currentID = self.currentUUID;
    
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        //原有逻辑、拨打电话
        [self old_startCallWithTelNum:self.callModel.telNum];
        [action fulfill];
        
    } else {
        [action fail];
    }
}

#pragma mark 接听电话
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSLog(@"CK: 接听电话");
    
    //原有逻辑、接听电话
    [self old_answerCallWithTelNum:self.callModel.telNum];
    [action fulfill];
}

#pragma mark 结束通话
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    NSLog(@"CK: 结束通话");
    
    NSUUID *currentID = self.currentUUID;
    if ([[action.callUUID UUIDString] isEqualToString:[currentID UUIDString]]) {
        
        //原有逻辑、挂断电话
        [self old_stopCall];
        [action fulfill];
        
    } else {
        [action fail];
    }
}

#pragma mark 通话静音
- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    NSLog(@"CK: %@",(action.muted)?@"通话静音":@"通话取消静音");
    //原有逻辑、通话静音
    [self isMute:(action.muted)];
    [action fulfill];
}

#pragma mark 群组通话
- (void)provider:(CXProvider *)provider performSetGroupCallAction:(CXSetGroupCallAction *)action {
    NSLog(@"CK: 群组通话");
    [action fulfill];
}

#pragma mark 双音频功能(通话中键盘点击)
- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
    NSLog(@"CK: 双音频功能 --- %@",action.digits);
    //原有逻辑、键盘点击
    [self clickKeyboardWithDigits:action.digits];
    [action fulfill];
}

#pragma mark 通话保留
- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
    NSLog(@"CK: %@",(action.onHold)?@"通话保留":(@"恢复通话"));
    
    [action fulfill];
}

#pragma mark 连接超时
- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    NSLog(@"CK: 连接超时");
}

#pragma mark audio session 设置
- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"CK: 音频开始");
    //开启音频
    [self openAudio];
}

#pragma mark 通话结束音频处理
- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    NSLog(@"CK: 音频结束");
    //关闭音频
    [self closeAudio];
}

#pragma mark - CXCallObserverDelegate
- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call{
    
    NSLog(@"CK: \ncallObserver---%ld\ncall.isOnHold---%d\ncall.isOutgoing---%d\ncall.hasConnected---%d\ncall.hasEnded---%d",callObserver.calls.count,call.isOnHold,call.isOutgoing,call.hasConnected,call.hasEnded);
    
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
        config.supportsVideo = NO;
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

#pragma mark - SET
- (void)setPhoneState:(SHCallPhoneState)phoneState{
    
    if (_phoneState == phoneState) {
        return;
    }
    
    //在这里配置根据状态需要的操作
    _phoneState = phoneState;
    
    //代理回调
    if ([self.delegate respondsToSelector:@selector(refreshCurrentCallStatus:)]) {
        [self.delegate refreshCurrentCallStatus:phoneState];
    }
}

#pragma mark - 初始化数据
- (void)clearData{

    if (self.currentUUID) {
        self.currentUUID = nil;
    }
    
    self.callModel = nil;
}

#pragma mark - 发送本地通知
+ (void)sendMessageWithMessage:(NSString *)message{
    
    // 1.创建一个本地通知
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    
    // 2.设置通知内容
    localNote.alertBody = message;

    // 3.执行通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}

@end
