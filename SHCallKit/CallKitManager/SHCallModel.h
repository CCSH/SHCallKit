//
//  SHCallModel.h
//  SHCallKit
//
//  Created by CSH on 2018/1/3.
//  Copyright © 2018年 CSH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 通话模型
 */
@interface SHCallModel : NSObject

//电话号码
@property (nonatomic, copy) NSString *telNum;
//用户名
@property (nonatomic, copy) NSString *userName;
//开始日期
@property (nonatomic, copy) NSDate *time;
//通话时长
@property (nonatomic, copy) NSString *duration;
//通话类型(呼出、呼入、未接等)
@property (nonatomic, assign) NSInteger callType;

@end
