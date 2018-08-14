//
//  TMISQRCodeController.m
//  TMIS
//
//  Created by xiangbin on 2018/8/12.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import "TMISQRCodeController.h"
#import <AVFoundation/AVFoundation.h>

@interface TMISQRCodeController ()
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end

@implementation TMISQRCodeController
/**
 *  退出二维码生成界面
 *
 *  @param sender <#sender description#>
 */
- (IBAction)tmis_quit:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置生成的图片尺寸和位置
    float w = 200;
  
    UIImage *img = [self generateCodeWithData:self.qrdata withSize:w];
    self.imgView.image = img;    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ===== 二维码相关操作 =====
// 生成二维码
- (UIImage *)generateCodeWithData:(NSData *)data withSize:(float)size
{
    // 1.创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复默认
    [filter setDefaults];
    // 3.给过滤器添加数据(正则表达式/账号和密码)
    [filter setValue:data forKeyPath:@"inputMessage"];
    // 4.获取输出的二维码
    CIImage *outputImage = [filter outputImage];
    // 5. 将CIImage转换成UIImage，并放大显示
    //    return [UIImage imageWithCIImage:outputImage scale:1.0 orientation:UIImageOrientationUp];
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:size];
}

/**
 *  根据CIImage生成指定大小的UIImage
 *
 *  @param image CIImage
 *  @param size  图片宽度
 */
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat) size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}


@end
