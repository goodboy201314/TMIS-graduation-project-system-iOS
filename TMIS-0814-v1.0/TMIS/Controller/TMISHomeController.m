//
//  TMISHomeController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/16.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import "TMISHomeController.h"
#import "XBPageView.h"
#import "TMISRecordController.h"

@interface TMISHomeController ()

@end

@implementation TMISHomeController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.title = @"医疗首页";
    self.view.backgroundColor = [UIColor colorWithRed:160.0/256 green:215.0/256 blue:222.0/256 alpha:1.0];
    //self.view.backgroundColor = [UIColor redColor];
    
    // 分页控件显示新闻 -- 本应该连接网络获取，这里只是为了方便阐述协议，简单使用一下
    XBPageView *pageView = [XBPageView pageView];
    float w = [UIScreen mainScreen].bounds.size.width;
    pageView.frame = CGRectMake(0, 64, w, 120);

    //pageView.imgNames = @[@"img_00",@"img_01",@"img_02",@"img_03"];
    pageView.imgNames = @[@"img6",@"img7",@"img8",@"img9"];
    [self.view addSubview:pageView];
        
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tmis_record:(id)sender {
    NSLog(@"点击了医疗记录按钮，要显示一个tableview");
    
    [self performSegueWithIdentifier:@"jum2record" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    TMISRecordController *desVc = segue.destinationViewController;
    desVc.uNamestr = self.uNamestr;
    desVc.clientfd = self.clientfd;
    desVc.sessionKey = self.sessionKey;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
