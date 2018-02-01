//
//  ViewController.m
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "ViewController.h"
#import "SHCallKitHeader.h"

#import <ifaddrs.h>
#import <arpa/inet.h>

@interface ViewController ()<SHCallManagerDelegate>

//我的号码
@property (weak, nonatomic) IBOutlet UILabel *myNum;
//来电号码
@property (weak, nonatomic) IBOutlet UILabel *otherNum;
//电话状态
@property (weak, nonatomic) IBOutlet UILabel *phoneState;
//呼出电话
@property (weak, nonatomic) IBOutlet UITextField *callNum;
//开始按钮
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
//停止按钮
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;

//接听电话按钮
@property (weak, nonatomic) IBOutlet UIButton *receiveBtn;
//拒绝电话按钮
@property (weak, nonatomic) IBOutlet UIButton *refuseBtn;

//电话帮助类
@property (nonatomic, strong) SHCallManager *callManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
 
    [self steup];
}

#pragma mark - 配置信息
- (void)steup{
    
    NSString *num = [NSString stringWithFormat:@"%.4d",arc4random()%10000];
    //我的电话
    self.myNum.text = [NSString stringWithFormat:@"我的号码:%@",num];
    
    //初始化
    self.callManager = [SHCallManager shareSHCallManager];
    self.callManager.delegate = self;
    
    //连接成功
    self.callManager.phoneState = SHCallPhoneState_None;
    [self refreshCurrentCallStatus:SHCallPhoneState_None];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 开始电话
- (IBAction)startClick:(id)sender {
    
    if (self.callNum.text.length) {
        
        //拨打电话
        [self.callManager startCallWithTelNum:self.callNum.text isVideo:NO];
    }
}

#pragma mark - 结束电话
- (IBAction)stopClick:(id)sender {
    
    [self.callManager stopCall];
    
}

#pragma mark - 接听电话
- (IBAction)receiveClick:(id)sender {
    
    [self.callManager receiveCall];
}

#pragma mark - 拒绝电话
- (IBAction)refuseClick:(id)sender {
    
    [self.callManager stopCall];
}

#pragma mark - SHCallManagerDelegate
- (void)refreshCurrentCallStatus:(SHCallPhoneState)status{

    switch (status) {
        case SHCallPhoneState_None://待机
        {
            if (self.callManager.callTimer) {
                [self.callManager.callTimer invalidate];
                self.callManager.callTimer = nil;
            }
            
            self.phoneState.text = @"待机中";
            self.otherNum.text = @"";
            self.startBtn.hidden = NO;
            self.stopBtn.hidden = YES;
            self.receiveBtn.hidden = YES;
            self.refuseBtn.hidden = YES;
        }
            break;
        case SHCallPhoneState_Out://呼出
        {
            self.phoneState.text = @"正在呼出";
            self.otherNum.text = @"";
            self.startBtn.hidden = YES;
            self.stopBtn.hidden = NO;
            self.receiveBtn.hidden = YES;
            self.refuseBtn.hidden = YES;
        }
            break;
        case SHCallPhoneState_In://呼入
        {
            self.phoneState.text = @"正在呼入";
            self.otherNum.text = @"";
            self.startBtn.hidden = YES;
            self.stopBtn.hidden = YES;
            self.receiveBtn.hidden = NO;
            self.refuseBtn.hidden = NO;
        }
            break;
        case SHCallPhoneState_Calling://通话中
        {
            self.callManager.callModel.time = [NSDate date];
            [self updateTimer];
            self.otherNum.text = self.callManager.callModel.telNum;
            self.startBtn.hidden = YES;
            self.stopBtn.hidden = NO;
            self.receiveBtn.hidden = YES;
            self.refuseBtn.hidden = YES;
        }
            break;
        case SHCallPhoneState_Disconnect://关闭
        {
            self.phoneState.text = @"未连接";
            self.otherNum.text = @"";
            self.startBtn.hidden = NO;
            self.stopBtn.hidden = YES;
            self.receiveBtn.hidden = YES;
            self.refuseBtn.hidden = YES;
        }
            break;
        default:
            break;
    }
}

#pragma mark 更新通话时间
- (void)updateTimer{
    
    //呼入或者呼出
    if (!self.callManager.callTimer) {
        
        self.callManager.callTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updataPhoneState) userInfo:nil repeats:YES];
    }
}

#pragma mark - 更新显示
- (void)updataPhoneState{
    
    //获取时间格式
    NSTimeInterval duration = ([NSDate date].timeIntervalSince1970 - self.callManager.callModel.time.timeIntervalSince1970);
    self.callManager.callModel.duration = [self.callManager.formatter stringFromTimeInterval:duration];
    
    WeakSelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.phoneState.text = weakSelf.callManager.callModel.duration;
    });
}

@end
