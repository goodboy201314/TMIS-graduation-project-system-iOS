//
//  TMISRegistrationController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/14.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//
#import "gmp-iPhoneOS.h"
#import "pbc.h"
#import "pbc_test.h"
#import "TMISRegistrationController.h"
#import "tmis_enc_denc.h"
#import "TMISQRCodeController.h"
#import <AVFoundation/AVFoundation.h>

const char split_char_key_agreement1[10]="tmis"; // "我";//
#define len_split_char_key_agreement1 strlen(split_char_key_agreement1)





@interface TMISRegistrationController ()
@property (weak, nonatomic) IBOutlet UITextField *uName;
@property (weak, nonatomic) IBOutlet UITextField *uPwd;
/** keyData */
//@property (nonatomic,strong) NSData* keysData;
@property (nonatomic, weak) AVCaptureSession *session;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *layer;
@end



@implementation TMISRegistrationController

static char public_key[1024] = "[8779246804865256595845410635551148521227644044548861627285453536743878386166265446937141101008408588690674901331738586548621281816777149434943936565852561, 5462710688655103662240594520449922001027729122965123487994410536107298056563228514615559984791707466524546778752823276552092115399599325705605166751646997]";
static char str_id[100] = {0};
static char str_pw[100] = {0};
static char str_save_b[100]={0};
static char str_save_constr[4096]={0};

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 用户输入的密码用点表示
    self.uPwd.secureTextEntry = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 界面按钮点击事件
// 步骤1中清空按钮点击事件
- (IBAction)tims_clear:(id)sender {
    // 清空用户名和密码输入框
    self.uName.text = @"";
    self.uPwd.text = @"";
    [self.uName becomeFirstResponder];
    
}

// 步骤1中确定按钮点击事件
- (IBAction)tmis_ok:(id)sender {
    // 退出键盘
    [self.view endEditing:YES];
    
    NSString *contentStr;
   
    // 检查用户的输入
    if(self.uName.text.length==0 || self.uPwd.text.length ==0)
    {
        contentStr =  @"用户名和密码不可以为空";
    }
    else
    {
        contentStr = @"输入合法，请接着完成后面2步";
        strcpy(str_id, self.uName.text.UTF8String);
        strcpy(str_pw, self.uPwd.text.UTF8String);
        
    }
    
    // 创建弹窗，提示用户相关信息
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:contentStr preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}


// 步骤2中生成二维码
- (IBAction)tmis_qrcode:(id)sender {
////  1. 生成随机数b，这里要生成一个随机数种子，否则的话，每一次的随机数都是相同的
    mpz_t b;
    mpz_init(b);
// void mpz_urandomb (mpz_t rop, gmp_randstate_t state, mp_bitcnt_t n)
//****** Generate a uniformly distributed random integer in the range 0 to 2n − 1, inclusive
// void gmp_randinit_mt (gmp randstate t state)
//***** Initialize state
// void gmp_randseed_ui (gmp randstate t state, unsigned long int seed)
    unsigned long int seed = (unsigned long int)time(NULL);
    gmp_randstate_t state;
    gmp_randinit_mt(state);
    gmp_randseed_ui(state,seed);
    mpz_urandomb(b,state,100); // 产生小于2^100的随机数
    
    char str_b[1024]={0};
// char * mpz_get_str (char *str, int base, mpz_t op)
    mpz_get_str (str_b, -16, b);  // 将随机数b转化为16进制字符串，保存
    printf("B = %s\n",str_b);
    printf("B_len = %ld\n",strlen(str_b));
    memset(str_save_b,0,sizeof(str_save_b));
    strcpy(str_save_b,str_b);
    
    //// 2.计算HPWi
    // 连接字符串 PWi || b
    int len1 = strlen(str_pw);
    int len2 = strlen(str_b);
    char *CONSTR =(char *)malloc(sizeof(char) * (len1+len2+1));
    memset(CONSTR,0,len1+len2+1);
    strncpy(CONSTR,str_pw,len1);
    strncpy(CONSTR+len1,str_b,len2);
    printf("CONSTR = %s\n",CONSTR);
    
    unsigned char bytes_HPWi[100]={0};
    sha1((unsigned char *)CONSTR, bytes_HPWi);
    
    
//// final：清理使用到的变量，mpz内部使用指针实现的，避免内存泄露
    mpz_clear(b);
    free(CONSTR);
    
//// 3.弹出二维码生成框   
    // 生成传递参数
    len1= strlen(str_id);
    len2 = get_length(bytes_HPWi);
//    int bytes2hex(const unsigned char* in, const int len, char *out);
    char *str_HPWi[1024]={0};
    bytes2hex(bytes_HPWi,len2,str_HPWi);
    printf("str_HPWi = %s\n",str_HPWi);
    
    len2 = strlen(str_HPWi);
    
    char *CONSTR1 = (char *)malloc(sizeof(char) *(len1+len2+2*len_split_char_key_agreement1+1));
    memset(CONSTR1, 0, len1+len2+len_split_char_key_agreement1+1);
    memcpy(CONSTR1, str_id, len1);
    memcpy(CONSTR1+len1, split_char_key_agreement1, len_split_char_key_agreement1);
    memcpy(CONSTR1+len1+len_split_char_key_agreement1, str_HPWi, len2);
    memcpy(CONSTR1+len1+len_split_char_key_agreement1+len2,split_char_key_agreement1, len_split_char_key_agreement1);
    printf("CONSTR1 = %s\n",CONSTR1);
    
   NSData *data = [NSData dataWithBytes:CONSTR1 length:strlen(CONSTR1)];
    printf("len = %ld\n",strlen(CONSTR1));
//    TMISQRCodeController *qrcode = [[TMISQRCodeController alloc] init];
//    qrcode.qrdata = data;
//    [self presentViewController:qrcode animated:YES completion:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TMISQRCodeController *qrcode = [storyboard instantiateViewControllerWithIdentifier:@"tmis_qr"];
    qrcode.qrdata = data;
    [self presentViewController:qrcode animated:YES completion:nil];
 


}



// 步骤3中点击存储注册信息，注册最后一步
- (IBAction)tmis_store:(id)sender {
//// 扫描二维码
    [self scanCode];
}

- (IBAction)tmis_save:(id)sender {
    //// 保存数据
    [self saveData];
}

- (void)saveData
{
////  分割出每一个字符串
    char str_Bi[2014]={0};
    char str_Ci[2014]={0};
    char str_m[2014]={0};
    char str_pkey[2014]={0};

    // str_Bi
    char *p = strtok(str_save_constr, split_char_key_agreement1);
    if(p) strcpy(str_Bi, p);
    printf("%s\n",str_Bi);
    // str_Ci
    p = strtok(NULL, split_char_key_agreement1);
    if(p) strcpy(str_Ci, p);
    printf("%s\n",str_Ci);
    // str_m
    p = strtok(NULL, split_char_key_agreement1);
    if(p) strcpy(str_m, p);
    printf("%s\n",str_m);
    // str_pkey
    p = strtok(NULL, split_char_key_agreement1);
    if(p) strcpy(str_pkey, p);
    printf("%s\n",str_pkey);

////   保存上面的字符串，还有str_save_b
    NSString *Bi = [[NSString alloc] initWithBytes:str_Bi length:strlen(str_Bi) encoding:NSUTF8StringEncoding];
    NSString *Ci = [[NSString alloc] initWithBytes:str_Ci length:strlen(str_Ci) encoding:NSUTF8StringEncoding];
    NSString *m = [[NSString alloc] initWithBytes:str_m length:strlen(str_m) encoding:NSUTF8StringEncoding];
    NSString *b = [[NSString alloc] initWithBytes:str_save_b length:strlen(str_save_b) encoding:NSUTF8StringEncoding];
    NSString *public_key = [[NSString alloc] initWithBytes:str_pkey length:strlen(str_pkey) encoding:NSUTF8StringEncoding];
    // 赋值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:Bi forKey:@"Bi"];
    [userDefaults setObject:Ci forKey:@"Ci"];
    [userDefaults setObject:m forKey:@"m"];
    [userDefaults setObject:b forKey:@"b"];
    [userDefaults setObject:public_key forKey:@"public_key"];
    
    //// 显示提示信息
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"保存信息成功" preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
//    [alert addAction:action1];
//    [self presentViewController:alert animated:YES completion:nil];
    
    //// 退出当前界面
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (void)scanCode
{
    // 1.创建捕捉会话
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.session = session;
    
    // 2.添加输入设备(数据从摄像头输入)
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [session addInput:input];
    
    // 3.添加输出数据(示例对象-->类对象-->元类对象-->根元类对象)
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput:output];
    
    // 3.1.设置输出元数据的类型(类型是二维码数据)
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    
    // 4.添加扫描图层
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.frame = self.view.bounds;
    [self.view.layer addSublayer:layer];
    self.layer = layer;
    
    // 5.开始扫描
    [session startRunning];
}

// 当扫描到数据时就会执行该方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *object = [metadataObjects lastObject];
        NSLog(@"hex_string:%@", object.stringValue);
        NSString *constr = object.stringValue;
        strcpy(str_save_constr,constr.UTF8String);

        NSLog(@">>>>>>>>>扫描扫描");
        // 停止扫描
        [self.session stopRunning];
        // 将预览图层移除
        [self.layer removeFromSuperlayer];
        
    } else {
        NSLog(@"没有扫描到数据");
    }
    
}




- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
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
