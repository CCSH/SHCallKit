//
//  AppDelegate.m
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import "AppDelegate.h"
#import <PushKit/PushKit.h>
#import "SHCallManager.h"

@interface AppDelegate ()<PKPushRegistryDelegate>

//是否在前台
@property (nonatomic, assign) BOOL inForeground;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //注册pushkit
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    //初始化callkit
    [SHCallManager shareSHCallManager];
    
    //设置
    self.inForeground = YES;
    
    return YES;
}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type{

    //截取tokenid
    NSString *tokenString = [[[[credentials.token description]stringByReplacingOccurrencesOfString:@"<" withString: @""] stringByReplacingOccurrencesOfString:@">"withString:@""]stringByReplacingOccurrencesOfString:@" "withString:@""];

    NSLog(@"credentialsToken === %@",tokenString);
    //将tokenid上传到服务器
    
    
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(nonnull PKPushPayload *)payload forType:(nonnull PKPushType)type {

    //内容
    NSLog(@"%@",payload.dictionaryPayload);
    
    NSDictionary *dic = payload.dictionaryPayload[@"aps"];
    NSString *alert = dic[@"alert"];
    
    //通过推送信息拿到电话号码
    NSString *telnum = @"1234567890";
    
    if (telnum.length) {//号码存在则进行拨打电话
        //进行拨打电话
        [[SHCallManager shareSHCallManager] answerCallWithTelNum:telnum];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    self.inForeground = NO;

    //start background task
    __block UIBackgroundTaskIdentifier background_task;
    
    //background task running time differs on different iOS versions.
    //about 10 mins on early iOS, but only 3 mins on iOS7.
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^{
        
        [application endBackgroundTask:background_task];
        background_task = UIBackgroundTaskInvalid;
        //end.
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            float remainingTime = [application backgroundTimeRemaining];
            if (remainingTime <= 3*60) {
                NSLog(@"remaining background time:%f", remainingTime);
                [NSThread sleepForTimeInterval:1.0];
                if (remainingTime <= 3.0 || self.inForeground) {
                    break;
                }
            }else{
                break;
            }
        }
        
        [application endBackgroundTask:background_task];
        background_task = UIBackgroundTaskInvalid;
    });
    
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler{

    //通过外部唤起进行拨打电话
    [[SHCallManager shareSHCallManager] starCallWithUserActivity:userActivity];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    self.inForeground = YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
