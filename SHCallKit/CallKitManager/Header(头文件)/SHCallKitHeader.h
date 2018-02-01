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

//weakself
#define WeakSelf __weak typeof(self) weakSelf = self;

//类
#import "SHCallManager.h"
#import "SHCallModel.h"
