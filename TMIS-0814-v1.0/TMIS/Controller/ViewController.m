//
//  ViewController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/12.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import "ViewController.h"
#import "gmp-iPhoneOS.h"
#import "pbc.h"
#import "pbc_test.h"

pairing_t pairing;
element_t P,a,Pa,b;
element_t out1,out2;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 验证: e(Pa,Pb)^b  ?= e(P,Pa)^b
    
    // 初始化双线性映射相关的参数
    NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
    const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    pbc_demo_pairing_init(pairing,ss);
    if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
    // 将参数P,a,Pa绑定到群上
    element_init_G1(P, pairing);   // G1群上点的初始化
    element_init_G1(Pa, pairing);
    element_init_GT(out1, pairing);  // GT群上点的初始化
    element_init_GT(out2, pairing);
    element_init_Zr(a, pairing);  // 随机数的初始化
    element_init_Zr(b, pairing);
    
    
    // 参数初始化
    element_from_hash(P, "a.properties", 12);
    element_random(a);
    element_random(b);
    
    // 计算Pa
    element_mul_zn(Pa, P, a);
    
    // 计算e(Pa,P)^b
    element_pairing(out1, Pa, P); // 没有^b
    element_pow_zn(out1, out1, b);
    
    // 计算e(P,Pa)^b
    element_pairing(out2, P, Pa); // 没有^b
    element_pow_zn(out2, out2, b);
    
    // 输出结果
    element_printf("out1：%B\n", out1);
    element_printf("out2：%B\n", out2);
    
}

#pragma mark - 第二部分
- (void)testpbc
{
    // 验证: e(Pa,P)^b  ?= e(P,Pa)^b
    
    // 初始化双线性映射相关的参数
    NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
    const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    pbc_demo_pairing_init(pairing,ss);
    if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
    // 将参数P,a,Pa绑定到群上
    element_init_G1(P, pairing);   // G1群上点的初始化
    element_init_G1(Pa, pairing);
    element_init_GT(out1, pairing);  // GT群上点的初始化
    element_init_GT(out2, pairing);
    element_init_Zr(a, pairing);  // 随机数的初始化
    element_init_Zr(b, pairing);
    
    
    // 参数初始化
    element_from_hash(P, "a.properties", 12);
    element_random(a);
    element_random(b);
    
    // 计算Pa
    element_mul_zn(Pa, P, a);
    
    // 计算e(Pa,P)^b
    element_pairing(out1, Pa, P); // 没有^b
    element_pow_zn(out1, out1, b);
    
    // 计算e(P,Pa)^b
    element_pairing(out2, P, Pa); // 没有^b
    element_pow_zn(out2, out2, b);
    
    // 输出结果
    element_printf("out1：%B\n", out1);
    element_printf("out2：%B\n", out2);
}

#pragma mark - 第一部分
// 测试ecc的点乘
- (void)computePa
{
    // 初始化双线性映射相关的参数
    NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
    const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    pbc_demo_pairing_init(pairing,ss);
    if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");
    // 将参数P,a,Pa绑定到群上
    element_init_G1(P, pairing);
    element_init_Zr(a, pairing);
    element_init_G1(Pa, pairing);
    // 参数初始化
    element_from_hash(P, "a.properties", 12);
    element_random(a);
    
    element_mul_zn(Pa, P, a);
    element_printf("加密：Pa = %B\n", Pa);
    
}
@end
