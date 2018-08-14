/*!  头文件方法实现的基本信息。
 @file TMISRecordData.m
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2018/7/17 Creation (此文档的版本信息)
   Copyright © 2018年 xiangbin1207. All rights reserved.
 */

#import "TMISRecordData.h"

@implementation TMISRecordData
+ (instancetype)initWithDict:(NSDictionary *)dict
{
    TMISRecordData *tdata = [[TMISRecordData alloc] init];
    
    // kvc: Key Value Coding
    [tdata setValuesForKeysWithDictionary:dict];
    return tdata;
}

@end
