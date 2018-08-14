//
//  TMISRecordCell.m
//  TMIS
//
//  Created by xiangbin on 2018/7/17.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import "TMISRecordCell.h"
#import "TMISRecordData.h"

@interface TMISRecordCell()
// 加密信息部分的控件
@property (weak, nonatomic) IBOutlet UILabel *enc_hex_str;

// 解密信息部分的控件
@property (weak, nonatomic) IBOutlet UILabel *date2;
@property (weak, nonatomic) IBOutlet UILabel *doctor2;
@property (weak, nonatomic) IBOutlet UILabel *symptom2;
@property (weak, nonatomic) IBOutlet UILabel *feedback2;
@property (weak, nonatomic) IBOutlet UILabel *posLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *height1;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *height2;

@end

@implementation TMISRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

// 1.设置数据内容
- (void)setRecordData:(TMISRecordData *)recordData
{
    _recordData = recordData;
    // 设置界面上的数据内容
    
    self.enc_hex_str.text= recordData.enc_string;

    // 计算Cell的真实高度
    [self layoutIfNeeded];
    float h1 = CGRectGetMaxY(self.enc_hex_str.frame) + 45;
    self.height1.constant = h1;
    
    [self layoutIfNeeded];
    self.date2.text = recordData.tmis_time;
    self.doctor2.text = recordData.tmis_doctor;
    self.symptom2.text = recordData.tmis_symptom;
    self.feedback2.text = recordData.tmis_feedback;
    
    [self layoutIfNeeded];
    float h2 = CGRectGetMaxY(self.feedback2.frame) + 10;
    self.height2.constant = h2;
    //NSLog(@"%@",NSStringFromCGRect(self.feedback1.frame));
    //NSLog(@"%@",NSStringFromCGRect(self.feedback2.frame));
    
    
    recordData.cell_height = CGRectGetMaxY(self.posLabel.frame) + h2 +18; // 18 = 5 + 10 + 3
    [self layoutIfNeeded];
    
}

#pragma mark - 封装cell的实现
// 封装
+ (TMISRecordCell *)cellWithTableView:(UITableView *)tableView
{
    TMISRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"record_cell"];
    
    if(!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
    }
    
    return cell;
}

                         
                         
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
