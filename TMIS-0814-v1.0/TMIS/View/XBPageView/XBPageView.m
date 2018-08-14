//
//  XBPageView.m
//  07-分页
//
//  Created by xiangbin on 2017/10/1.
//  Copyright © 2017年 xiangbin1207. All rights reserved.
//

#import "XBPageView.h"

@interface XBPageView() <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
/**  时间控制器  */
@property (nonatomic,strong) NSTimer* timer;

@end

@implementation XBPageView

+(instancetype)pageView
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self startTimer];
}

- (void)setImgNames:(NSArray *)imgNames
{
    _imgNames = imgNames;
    // 添加图片到scrollView中
    // 凡是涉及到封装属性，都要考虑多次赋值的情况
    // 所以在添加图片前，应该先清空
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for (NSInteger i=0; i<imgNames.count; i++) {
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.image = [UIImage imageNamed:imgNames[i]];
        // 这里不可以设置frame，frame属性要在layout里面设置
        [self.scrollView addSubview:imgView];
    }
    
    // 设置contentSize -- layoutsubviews
    // 设置水平滚动条不可见
    self.scrollView.showsHorizontalScrollIndicator = NO;
    // 设置pageControl
    self.pageControl.numberOfPages = imgNames.count;
    // 设置分页
    self.scrollView.pagingEnabled = YES;
    
    // 设置pageControl为单页时，隐藏小圆点
    self.pageControl.hidesForSinglePage = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    
    // 获得scrollview的宽度和高度
    CGFloat w = self.scrollView.frame.size.width;
    CGFloat h = self.scrollView.frame.size.height;
    // 设置contentSize
    self.scrollView.contentSize = CGSizeMake(w * self.imgNames.count, 0);
    
    // 设置每一个ImgeView的frame
    for (NSInteger i=0; i<self.imgNames.count; i++) {
        UIImageView *imgView = self.scrollView.subviews[i];
        imgView.frame = CGRectMake(i * w, 0, w, h);
    }
}

#pragma mark - UIScrollViewDelegate
// 监听滚动，控制页面控件的显示
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 计算当前应该是第几页
    CGFloat offsetX = self.scrollView.contentOffset.x;
    NSInteger currentPage = (NSInteger)(offsetX / self.scrollView.frame.size.width + 0.5);
    // 设置
    self.pageControl.currentPage = currentPage;
}

// 拖拽时停止定时器
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self stopTimer];
}

// 停止拖拽时开启定时器
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self startTimer];
}

#pragma mark - 定时器
// 开启定时器
- (void)startTimer
{
    // 这里有两个强指针指向创建的timer，一个是系统自己的，一个是自己定义的（使用了strong修饰符）
    self.timer =[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
    // 设置控制器的优先级和UI操作一样
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
}

// 停止定时器
- (void)stopTimer
{
    [self.timer invalidate]; // 系统的强指针死
    self.timer = nil; // 自己设置的强指针死
}

// 下一页
- (void)nextPage
{
    // 获得当前页
    NSInteger currentPage = self.pageControl.currentPage;
    // 计算下一页
    NSInteger nextPage = (currentPage +1) % self.pageControl.numberOfPages;
    
    // 计算contentOffset
    CGFloat w = self.scrollView.frame.size.width;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.contentOffset = CGPointMake(nextPage * w, 0);
    }];
}

#pragma mark - 小圆点颜色的设置
- (void)setCurrentDotColor:(UIColor *)currentDotColor
{
        self.pageControl.currentPageIndicatorTintColor =currentDotColor;
}

- (void)setOtherDotColor:(UIColor *)otherDotColor
{
    self.pageControl.pageIndicatorTintColor = otherDotColor;
}

@end
