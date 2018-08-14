//
//  TMISRecordCell.h
//  TMIS
//
//  Created by xiangbin on 2018/7/17.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TMISRecordData;

@interface TMISRecordCell : UITableViewCell
/**  数据模型  */
@property (nonatomic,strong) TMISRecordData* recordData;



// 封装cell的创建
+ (TMISRecordCell *)cellWithTableView:(UITableView *)tableView;
@end
