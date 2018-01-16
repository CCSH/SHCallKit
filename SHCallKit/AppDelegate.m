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

@property (nonatomic, assign) BOOL inForeground;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //以下注册代码及详细证书配置可以在苹果PushKit官方文档中找到,在此不做赘述,详见:https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html#//apple_ref/doc/uid/TP40015243-CH30-SW1
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
    //初始化
    [SHCallManager shareSHCallManager];
    
    self.inForeground = true;
    
    return YES;
}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type{

    NSLog(@"credentialsToken=%@",credentials.token);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    self.inForeground = false;

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

    [[SHCallManager shareSHCallManager] starCallWithUserActivity:userActivity];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    self.inForeground = true;
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
