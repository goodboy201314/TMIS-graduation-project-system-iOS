//
//  XBPageView.h
//  07-分页
//
//  Created by xiangbin on 2017/10/1.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XBPageView : UIView
// ====================== 属性 ===================
/**  图片数组  */
@property (nonatomic,strong) NSArray* imgNames ;
/**  当前页的小圆点的颜色  */
@property (nonatomic,strong) UIColor* currentDotColor;
/**  其他页小圆点的颜色  */
@property (nonatomic,strong) UIColor* otherDotColor;


// ====================== 方法 ===================
/** 构造方法 */
+(instancetype)pageView;

@end
