/*!  头文件的基本信息。
 @file TMISRecordData.h
 @brief 关于这个源文件的简单描述
 @author 项斌
 @version    1.00 2018/7/17 Creation (此文档的版本信息)
   Copyright © 2018年 xiangbin1207. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface TMISRecordData : NSObject
/**  记录的时间  */
@property (nonatomic,copy) NSString* tmis_time;

/**  记录的医生  */
@property (nonatomic,copy) NSString* tmis_doctor;

/**  症状描述  */
@property (nonatomic,copy) NSString* tmis_symptom;

/**  就诊反馈  */
@property (nonatomic,copy) NSString* tmis_feedback;

/**  加密的字符串  */
@property (nonatomic,copy) NSString* enc_string;

/**  cell的高度  */
@property (nonatomic,assign) float cell_height;


+ (instancetype)initWithDict:(NSDictionary *)dict;

@end
