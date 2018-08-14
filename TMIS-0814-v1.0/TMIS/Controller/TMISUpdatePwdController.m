//
//  TMISUpdatePwdController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/14.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//
#import "gmp-iPhoneOS.h"
#import "pbc.h"
#import "pbc_test.h"
#import "TMISUpdatePwdController.h"
#include "tmis_enc_denc.h"

@interface TMISUpdatePwdController ()
@property (weak, nonatomic) IBOutlet UITextField *uName;
@property (weak, nonatomic) IBOutlet UITextField *uPwd;
@property (weak, nonatomic) IBOutlet UITextField *uNewPwd;

@end

@implementation TMISUpdatePwdController
#pragma mark - 协议运行过程中使用的相关参数
static char str_pw_new[100]={0};
static char str_Bi[1024]={0};
static char str_Ci[1024]={0};
static char str_m[100]={0};
static char str_b[100]={0};
static char str_id[100]={0};
static char str_pw[100]={0};
static mpz_t m;
unsigned char bytes_HPWi[100]={0};

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 密码输入框以密文显示
    self.uPwd.secureTextEntry = YES;
    self.uNewPwd.secureTextEntry = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 界面按钮点击事件
// 步骤1中清空按钮点击事件
- (IBAction)tmis_clear:(id)sender {
    self.uName.text = @"";
    self.uPwd.text = @"";
    [self.uName becomeFirstResponder];
}

- (IBAction)tmis_ok:(id)sender {
    [self.view endEditing:YES];
    
    NSString *contentStr;
    
    // 检查用户的输入
    if(self.uName.text.length==0 || self.uPwd.text.length ==0)
    {
        contentStr =  @"用户名和密码不可以为空";
    }
    else
    {
        contentStr = @"请接着完成第2步：验证用户身份";
    }
    
    // 创建弹窗，提示用户相关信息
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:contentStr preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
    
}

// 步骤2中，验证用户身份按钮点击事件
- (IBAction)tmis_identify:(id)sender {
////////    验证用户身份
    NSString *userid = self.uName.text;
    NSString *userpw = self.uPwd.text;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *Bi = [userDefaults stringForKey:@"Bi"];
    NSString *Ci = [userDefaults stringForKey:@"Ci"];
    NSString *m_param = [userDefaults stringForKey:@"m"];
    NSString *b = [userDefaults stringForKey:@"b"];
    
    NSLog(@"Bi = %@",Bi);
    NSLog(@"Ci = %@",Ci);
    NSLog(@"m = %@",m_param);
    NSLog(@"b = %@",b);

    // 转换成字符串
    strcpy(str_Bi,Bi.UTF8String);
    strcpy(str_Ci, Ci.UTF8String);
    strcpy(str_m, m_param.UTF8String);
    strcpy(str_b, b.UTF8String);
    strcpy(str_id, userid.UTF8String);
    strcpy(str_pw, userpw.UTF8String);
    
////////  1.计算HPWi
    int len1 = strlen(str_pw);
    int len2 = strlen(str_b);
    char *CONSTR =(char *)malloc(sizeof(char) * (len1+len2)+1);
    memset(CONSTR,0,len1+len2+1);
    strncpy(CONSTR,str_pw,len1);
    strncpy(CONSTR+len1,str_b,len2);
    printf("CONSTR = %s\n",CONSTR);
    //unsigned char bytes_HPWi[100]={0};
    sha1((unsigned char *)CONSTR, bytes_HPWi);
    free(CONSTR);
    
////////  2.计算Bi*    (Bi2)
    len1 = strlen(str_id);
    len2 = strlen((char *)bytes_HPWi);
    char *CONSTR2 =(char *)malloc(sizeof(char) * (len1+len2)+1);
    memset(CONSTR2,0,len1+len2+1);
    memcpy(CONSTR2,str_id,len1);
    memcpy(CONSTR2+len1,bytes_HPWi,len2);
    
    unsigned char bytes_temp1[1024]={0};
    sha1((unsigned char*)CONSTR2,bytes_temp1);   // h( IDi || HPWi  )
    // 转化成mpz_t类型，然后mod
    char str_temp1[1024]={0};
    bytes2hex(bytes_temp1,strlen((char *)bytes_temp1),str_temp1);
    printf("str_temp1 = %s\n",str_temp1);
    mpz_t mpz_temp1;
    mpz_init_set_str(mpz_temp1,str_temp1,16);
    gmp_printf("mpz_temp1 = %Zd\n",mpz_temp1);
    
    mpz_t mpz_res;
    mpz_init(mpz_res);
    mpz_init_set_str(m,str_m,16);
    //	void mpz_mod (mpz t r, mpz t n, mpz t d) [Function]
    //**** Set r to n mod d.
    mpz_mod(mpz_res,mpz_temp1,m);
    gmp_printf("mpz_res = %Zd\n",mpz_res);  // h( IDi || HPWi  ) mod m
    // 将mpz_res转化为字符串
    //  char * mpz_get_str (char *str, int base, mpz t op);
    char str_res[1024]={0};
    mpz_get_str(str_res,-16,mpz_res);
    printf("str_res = %s\n",str_res);
    unsigned char bytes_Bi[100]={0};
    sha1((unsigned char *)str_res,bytes_Bi);   //  h ( h( IDi || HPWi  ) mod m )

//////// 3.比较Bi和Bi*是否相等
    char str_Bi2[1024]={0};
    bytes2hex(bytes_Bi,strlen((char *)bytes_Bi),str_Bi2);
    NSString *str_hint;
    if(strcmp(str_Bi2,str_Bi)==0) {
//        printf("用户身份验证通过。。。\n");
        str_hint = @"用户身份验证通过，请接着完成第3步：输入新密码";
    } else {
//        printf("用户身份验证失败。。。\n");
        str_hint = @"用户身份验证失败";
    }
    
    free(CONSTR);
    free(CONSTR2);
    mpz_clear(mpz_temp1);
    mpz_clear(mpz_res);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:str_hint preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}


// 步骤3中，确定按钮点击事件
- (IBAction)tmis_pwdOk:(id)sender {
    [self.view endEditing:YES];
  
    NSString *userpw2 = self.uNewPwd.text;
    NSString *str_hint;
    if(userpw2.length==0) {
        str_hint = @"新密码不可以为空";
    }  else {
        memset(str_pw_new, 0, sizeof(str_pw_new));
        strcpy(str_pw_new, userpw2.UTF8String);
        str_hint = @"新密码获取成功，请接着完成第4步：更新密码";
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:str_hint preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}

// 步骤4中，更新新密码
- (IBAction)tmis_updatePwd:(id)sender {
///////// 	5.计算HPWi_new
    int len1 = strlen(str_pw_new);
    int len2 = strlen(str_b);
    char *CONSTR3 =(char *)malloc(sizeof(char) * (len1+len2)+1);
    memset(CONSTR3,0,len1+len2+1);
    strncpy(CONSTR3,str_pw_new,len1);
    strncpy(CONSTR3+len1,str_b,len2);
    printf("CONSTR3 = %s\n",CONSTR3);
    unsigned char bytes_HPWi_new[100]={0};
    sha1((unsigned char *)CONSTR3, bytes_HPWi_new);
    char str_HPWi_new[1024]={0};
    bytes2hex(bytes_HPWi_new,strlen((char *)bytes_HPWi_new),str_HPWi_new);
    
/////////  6.计算Bi_new
    len1 = strlen(str_id);
    len2 = strlen((char *)bytes_HPWi_new);
    char *CONSTR4 =(char *)malloc(sizeof(char) * (len1+len2)+1);
    memset(CONSTR4,0,len1+len2+1);
    memcpy(CONSTR4,str_id,len1);
    memcpy(CONSTR4+len1,bytes_HPWi_new,len2);
    
    unsigned char bytes_temp1_new[1024]={0};
    sha1((unsigned char*)CONSTR4,bytes_temp1_new);	 // h( IDi || HPWi	)
    // 转化成mpz_t类型，然后mod
    char str_temp1_new[1024]={0};
    bytes2hex(bytes_temp1_new,strlen((char *)bytes_temp1_new),str_temp1_new);
    printf("str_temp1_new = %s\n",str_temp1_new);
    mpz_t mpz_temp1_new;
    mpz_init_set_str(mpz_temp1_new,str_temp1_new,16);
    gmp_printf("mpz_temp1 = %Zd\n",mpz_temp1_new);
    
    mpz_t mpz_res_new;
    mpz_init(mpz_res_new);
    //	void mpz_mod (mpz t r, mpz t n, mpz t d) [Function]
    //**** Set r to n mod d.
    mpz_mod(mpz_res_new,mpz_temp1_new,m);
    gmp_printf("mpz_res = %Zd\n",mpz_res_new);	// h( IDi || HPWi  ) mod m
    // 将mpz_res转化为字符串
    //	char * mpz_get_str (char *str, int base, mpz t op);
    char str_res_new[1024]={0};
    mpz_get_str(str_res_new,-16,mpz_res_new);
    printf("str_res_new = %s\n",str_res_new);
    unsigned char bytes_Bi_new[100]={0};
    sha1((unsigned char *)str_res_new,bytes_Bi_new);
    char str_Bi_new[1024]={0};
    bytes2hex(bytes_Bi_new,strlen((char *)bytes_Bi_new),str_Bi_new);
    
///////// 7.获得Ai
    mpz_t mpz_Ci,mpz_HPWi,mpz_Bi;
    mpz_t mpz_Ai;
    mpz_init(mpz_Ai);
    
    mpz_init_set_str(mpz_Ci,str_Ci,16);
    gmp_printf("mpz_Ci = %Zd\n", mpz_Ci);
    mpz_init_set_str(mpz_Bi,str_Bi,16);
    gmp_printf("mpz_Bi = %Zd\n", mpz_Bi);
    char str_HPWi[1024]={0};
    bytes2hex(bytes_HPWi,strlen((char *)bytes_HPWi),str_HPWi);
    mpz_init_set_str(mpz_HPWi,str_HPWi,16);  // mpz_HPWi
    gmp_printf("mpz_HPWi = %Zd\n", mpz_HPWi);
    mpz_xor(mpz_Ai,mpz_Ci,mpz_HPWi);
    mpz_xor(mpz_Ai,mpz_Ai,mpz_Bi);
    gmp_printf("mpz_Ai = %Zd\n", mpz_Ai);
    
    
///////// 8.计算Ci_new
    mpz_t mpz_HPWi_new,mpz_Bi_new;
    mpz_t mpz_Ci_new;
    mpz_init(mpz_Ci_new);
    mpz_init_set_str(mpz_HPWi_new,str_HPWi_new,16);  // mpz_HPWi
    mpz_init_set_str(mpz_Bi_new,str_Bi_new,16);  // mpz_HPWi
    mpz_xor(mpz_Ci_new,mpz_Ai,mpz_HPWi_new);
    mpz_xor(mpz_Ci_new,mpz_Ci_new,mpz_Bi_new);
    
    char str_Ci_new[1024]={0};
    // 将mpz_res转化为字符串
    //  char * mpz_get_str (char *str, int base, mpz t op);	
    mpz_get_str(str_Ci_new,-16,mpz_Ci_new);
    
    printf("str_Bi_new = %s\n",str_Bi_new);
    printf("str_Ci_new = %s\n",str_Ci_new);
    
/////////  重新写入
    NSString *Bi_new = [[NSString alloc] initWithBytes:str_Bi_new length:strlen(str_Bi_new) encoding:NSUTF8StringEncoding];
    NSString *Ci_new = [[NSString alloc] initWithBytes:str_Ci_new length:strlen(str_Ci_new) encoding:NSUTF8StringEncoding];
   
    // 赋值
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:Bi_new forKey:@"Bi"];
    [userDefaults setObject:Ci_new forKey:@"Ci"];
  
    free(CONSTR3);
    free(CONSTR4);
    mpz_clear(mpz_temp1_new);
    mpz_clear(mpz_res_new);
    mpz_clear(mpz_Ci);
    mpz_clear(mpz_HPWi);
    mpz_clear(mpz_Bi);
    mpz_clear(mpz_Ai);
    mpz_clear(mpz_HPWi_new);
    mpz_clear(mpz_Bi_new);
    mpz_clear(mpz_Ci_new);

    
    [self dismissViewControllerAnimated:YES completion:nil];
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
