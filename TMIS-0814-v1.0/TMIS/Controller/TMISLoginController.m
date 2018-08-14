//
//  TMISLoginController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/14.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import "TMISLoginController.h"
#import "TMISRegistrationController.h"
#import "TMISUpdatePwdController.h"
#import "TMISHomeController.h"
#import "TMISHealthPlanController.h"
#import "TMISOnlineController.h"
#import "TMISMsgController.h"
#import "TMISIO.h"
#import "tmis_enc_denc.h"
#import "gmp-iPhoneOS.h"
#import "pbc.h"
#import "pbc_test.h"

#define XBLog(...) NSLog(__VA_ARGS__)

const char split_char_key_agreement[10]="我"; // "BB";//
#define len_split_char_key_agreement strlen(split_char_key_agreement)


@interface TMISLoginController ()
@property (weak, nonatomic) IBOutlet UITextField *uName;
@property (weak, nonatomic) IBOutlet UITextField *uPwd;

@end

@implementation TMISLoginController
#pragma mark - TCP/IP连接的相关相关的参数
static NSString * host =@"192.168.2.8";
static NSString * port = @"8888";
static int clientSocket = -1;

#pragma mark - 密钥认证相关参数
static char str_id[100]={0};
static char str_pw[100]={0};
static char str_Bi[1024]={0};
static char str_Ci[1024]={0};
static char str_m[100]={0};
static char str_b[100]={0};
static char public_key[1024]={0};
static char str_session_key[20]={0};


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

#pragma mark - 注册
// 注册按钮点击事件
- (IBAction)registerUser:(id)sender {
    NSLog(@"xiangbin is a good boy - registerUser!");
    
    // 创建并显示注册界面 ----- 添加窗⼝的根控制器 - 从storyboard⾥⾯来
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TMISRegistrationController *regVc = [storyboard instantiateViewControllerWithIdentifier:@"tmis_reg"];
    
    [self presentViewController:regVc animated:YES completion:nil];
    
}


#pragma mark - 修改密码
// 修改密码按钮点击事件
- (IBAction)updatePwd:(id)sender {
    NSLog(@"xiangbin is a good boy - updatePwd!");
    
    // 创建并显示修改密码界面 ----- 添加窗⼝的根控制器 - 从storyboard⾥⾯来
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TMISUpdatePwdController *updateVc = [storyboard instantiateViewControllerWithIdentifier:@"tmis_updatePwd"];
    
    [self presentViewController:updateVc animated:YES completion:nil];
}

#pragma mark - 登录
// 登录按钮点击事件
- (IBAction)login:(id)sender {
    [self.view endEditing:YES];
    NSLog(@"xiangbin is a good boy - login!");
    
//////////////////  1. 检查用户的输入是否合法
    if(self.uName.text.length==0 || self.uPwd.text.length ==0)
    {
        // 创建弹窗，提示用户相关信息
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"用户名和密码不可以为空" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action1];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
////////////////// 2. 连接服务器，检测用户是否是注册的
//    - (void)connectToServer:(NSString *)ip port:(int)port
    int ret = [self key_agreement]; // -1:用户验证不通过  -2:网络连接出现问题  0：正常
    NSString *str_hint;
    if(ret==-1) {
        str_hint = @"用户身份验证不通过";
    } else if(ret==-2) {
        str_hint = @"网络连接出现问题";
    }
    
    if(ret!=0) {
        // 创建弹窗，提示用户相关信息
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:str_hint preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action1];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
//////////////////  3.创建主界面
    UITabBarController *tabVc = [[UITabBarController alloc] init];
    // 给tabBarController添加子控制器
    // tab1 tmis_home
    //TMISHomeController *homeVc = [[TMISHomeController alloc] init];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    TMISHomeController *homeVc = [storyboard instantiateViewControllerWithIdentifier:@"tmis_home"];
    homeVc.uNamestr = self.uName.text; //传递用户名
    homeVc.clientfd = clientSocket; // 传递客户端连接的套接字
    NSString *sessionKey = [NSString stringWithUTF8String:str_session_key];
    homeVc.sessionKey = sessionKey;
    UINavigationController *navHome = [[UINavigationController alloc] initWithRootViewController:homeVc];
    navHome.tabBarItem.title = @"医疗首页";
    navHome.tabBarItem.image = [UIImage imageNamed:@"icon1"];
    // tab2
    TMISHealthPlanController *healthPlanVc = [[TMISHealthPlanController alloc] init];
    UINavigationController *navHealthPlan = [[UINavigationController alloc] initWithRootViewController:healthPlanVc];
     navHealthPlan.tabBarItem.title = @"健康计划";
    navHealthPlan.tabBarItem.image = [UIImage imageNamed:@"icon2"];
    // tab3
    TMISOnlineController *onlineVc = [[TMISOnlineController alloc] init];
    UINavigationController *navOnline = [[UINavigationController alloc] initWithRootViewController:onlineVc];
    navOnline.tabBarItem.title = @"在线问诊";
    navOnline.tabBarItem.image = [UIImage imageNamed:@"icon3"];
    // tab4
    TMISMsgController *msgVc = [[TMISMsgController alloc] init];
    UINavigationController *navMsg = [[UINavigationController alloc] initWithRootViewController:msgVc];
    msgVc.tabBarItem.image = [UIImage imageNamed:@"icon4"];
    navMsg.tabBarItem.title = @"我的消息";
    // add to tabVc
    tabVc.viewControllers = @[navHome,navHealthPlan,navOnline,navMsg];
    
    [self presentViewController:tabVc animated:YES completion:nil];
    
    
}

#pragma mark - 协议认证部分
// 将字符串转化为绝对时间
-(long)string2time:(NSString*)timeStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"YYYYMMddHHmmss"];
    
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    
    NSDate* date = [formatter dateFromString:timeStr];
    return (long)[date timeIntervalSince1970];
    
    return 0;
}

// 将绝对时间转化为字符串
-(NSString*)time2string:(long)t
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"YYYYMMddHHmmss"];
    
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [formatter setTimeZone:timeZone];
    
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:t];
   // NSLog(@"1296035591  = %@",confromTimesp);
    
    NSString *confromTimespStr = [formatter stringFromDate:confromTimesp];
    //NSLog(@"confromTimespStr =  %@",confromTimespStr);
    
    return confromTimespStr;
    
}

-(int)key_agreement
{
////////////// 1. 首先得到你参数
    [self getParam];

////////////// 2.本地验证用户是否正确
    //// 1.计算HPWi
    int len1 = strlen(str_pw);
    int len2 = strlen(str_b);
    char *CONSTR =(char *)malloc(sizeof(char) * (len1+len2)+1);
    memset(CONSTR,0,len1+len2+1);
    strncpy(CONSTR,str_pw,len1);
    strncpy(CONSTR+len1,str_b,len2);
    printf("CONSTR = %s\n",CONSTR);
    unsigned char bytes_HPWi[100]={0};
    sha1((unsigned char *)CONSTR, bytes_HPWi);
    
    //// 2.计算Bi*    (Bi2)
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
    
    mpz_t mpz_res,m;
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
    
    //// 3.比较Bi和Bi*是否相等
    char str_Bi2[1024]={0};
    bytes2hex(bytes_Bi,strlen((char *)bytes_Bi),str_Bi2);
    if(strcmp(str_Bi2,str_Bi)==0){
        printf("用户身份验证通过。。。\n");
    } else{
        printf("用户身份验证失败。。。\n");
        return -1;
    }

    //// 4.计算Ai
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
    
    
    //// 5.手机端生成参数Rc
    pairing_t pairing;
//    char s[16384];
//    FILE *fp = stdin;
//    fp = fopen("a.param", "r");
//    if (!fp) pbc_die("error opening a.param");
//    
//    size_t count = fread(s, 1, 16384, fp);
//    if (!count) pbc_die("input error");
//    fclose(fp);
//    
//    if (pairing_init_set_buf(pairing, s, count)) pbc_die("pairing init failed");
    NSString * fullPath = [[NSBundle mainBundle] pathForResource:@"a.param" ofType:nil];
    const char *ss = [fullPath cStringUsingEncoding:NSUTF8StringEncoding];
    
    pbc_demo_pairing_init(pairing,ss);
    if (!pairing_is_symmetric(pairing)) pbc_die("pairing must be symmetric");

    
    // ======> pairing 初始化完成
    element_t element_P,elemetn_secret_key,element_public_key;  // 这些要定义成全局的
    element_t element_Rc,element_rc,element_k1;
    element_t element_Ai;
    
    element_init_G1(element_P,pairing);
    element_init_G1(elemetn_secret_key,pairing);
    element_init_G1(element_public_key,pairing);
    element_init_G1(element_Rc,pairing);
    element_init_G1(element_rc,pairing);
    element_init_G1(element_k1,pairing);
    element_init_G1(element_Ai,pairing);
    
    // 参数初始化
    char hash_str[30] = "xiangbin is a good boy!";
    element_from_hash(element_P, hash_str, strlen(hash_str));
    element_printf("element_P = %B\n", element_P);  // 赋值：element_P
    
    element_random(element_rc);    // element_rc
    element_set_str(element_public_key,public_key,10); // element_public_key
    element_printf("element_public_key = %B\n", element_public_key);
    // 这里将mpz_Ai转化成element，发现转化不成功，所以做一个转换
    //	void element_set_mpz(element_t e, mpz_t z)
    //	element_set_mpz(element_ai,mpz_ai);
    //	element_printf("element_ai = %B\n", element_ai);
    char str_Ai[1024]={0};
    // char * mpz_get_str (char *str, int base, mpz_t op)
    mpz_get_str (str_Ai, 10, mpz_Ai);
    element_from_hash(element_Ai, str_Ai, strlen(str_Ai));
    element_printf("element_Ai = %B\n", element_Ai);
    
    element_mul(element_Rc,element_rc,element_Ai);
    element_mul(element_Rc,element_Rc,element_P); // 得出element_Rc
    
    //// 5.计算k1
    element_mul(element_k1,element_rc,element_Ai);
    element_mul(element_k1,element_k1,element_public_key);
    
    //// 6.计算Hi
    time_t t1 = time(NULL);
    printf("t1: %ld\n",t1);
    char str_t1[30]={0};
    NSString *timeStr = [self time2string:t1];
    strcpy(str_t1, timeStr.UTF8String);
    //time2string(t1, str_t1, sizeof(str_t1)/sizeof(char));
    printf("str_time = %s\n",str_t1);
    
    len1=strlen(str_id);
    len2=strlen(str_Ai);
    int len3=strlen(str_t1);
    
    char *CONSTR3 = (char *)malloc(sizeof(char)*(len1+len2+len3+1+3*len_split_char_key_agreement));
    memset(CONSTR3,0,len1+len2+len3+1+3*len_split_char_key_agreement);
    strncpy(CONSTR3,str_id,len1);
    strncpy(CONSTR3+len1,split_char_key_agreement,len_split_char_key_agreement);
    strncpy(CONSTR3+len1+len_split_char_key_agreement,str_Ai,len2);
    strncpy(CONSTR3+len1+len_split_char_key_agreement+len2,split_char_key_agreement,len_split_char_key_agreement);
    strncpy(CONSTR3+len1+len_split_char_key_agreement*2+len2,str_t1,len3);
    strncpy(CONSTR3+len1+len_split_char_key_agreement*2+len2+len3,split_char_key_agreement,len_split_char_key_agreement);
    printf("str_Hi = %s\n",CONSTR3);
    printf("str_Hi_len = %ld\n",strlen(CONSTR3));
    
    // 计算加密密钥
    unsigned char bytes_md5_k1[50]={0};
    //	int md5(const  unsigned char* in, unsigned char* out);
    //	int element_snprint(char *s, size_t n, element_t e)
    char str_k1[1024]={0};
    element_snprint(str_k1,sizeof(str_k1),element_k1);
    md5((unsigned char *)str_k1,bytes_md5_k1);
    ////////// 注意：如果使用不可见字符加密，有时候会出错
    char str_md5_k1[50]={0};
    char str_temp[50]={0};
    //	int bytes2hex(const unsigned char* in, const int len, char *out);
    bytes2hex(bytes_md5_k1,strlen((char *)bytes_md5_k1),str_temp);
    strncpy(str_md5_k1,str_temp,16);
    printf("str_md5_k1 = %s\n",str_md5_k1);
    
    unsigned char bytes_Hi[4096]={0};
    aes_encrypt((unsigned char *)CONSTR3,(unsigned char *)str_md5_k1,bytes_Hi);
    //// 7.将Rc转化为字节流传输
    unsigned char bytes_Rc[4096]={0};
    element_to_bytes(bytes_Rc, element_Rc);
    
    printf("key_agreement:手机端生成并且发送参数。。。\n");
    
////////////// 3.连接服务器协商密钥
    clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == clientSocket) {
        XBLog(@"客户端socket创建失败");
        return -2;
    }
    
     /* 填写sockaddr_in结构*/
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons([port intValue]);
    //    inet_pton(AF_INET, ip.UTF8String, &addr.sin_addr.s_addr);
    addr.sin_addr.s_addr = inet_addr(host.UTF8String);
    
    int connectResult = connect(clientSocket, (const struct sockaddr *)&addr, sizeof(addr));
    if (connectResult == 0) {
        XBLog(@"客户端connect成功!");
    } else {
        XBLog(@"客户端connect失败，errno=%d",errno);
        return -2;
    }
    
    // 发送数据
    len1 = get_length(bytes_Hi);
    len2 = get_length(bytes_Rc);
    char str_Hi[2048]={0};
    char str_Rc[2048]={0};
    char sendata[4096]={0};
    bytes2hex(bytes_Hi, len1, str_Hi);
    bytes2hex(bytes_Rc, len2, str_Rc);
    strcat(sendata, str_Hi);
    strcat(sendata, split_char_key_agreement);
    strcat(sendata, str_Rc);
    strcat(sendata, split_char_key_agreement);
    
    
//////////  发送数据
    //    ssize_t sendLen = send(clientSocket, str, strlen(str), 0);
    //    ssize_t sendLen = write(clientSocket, str, strlen(str));
    //    /** 发送的数据包相关信息 */
    //    typedef struct tmis_packet
    //    {
    //        unsigned int len;                ///< 此次发送数据的长度
    //        char flag;                              ///< 此次发送数据的类型 ，协商密钥的，安全通信的
    //        char buf[BUFLEN];                  ///< 此次发送的数据
    //    }tmis_packet_t;
    
    tmis_packet_t sendpacket;
    memset(&sendpacket, 0, sizeof(sendpacket));
    sendpacket.flag = 1;
    strcpy(sendpacket.buf , sendata);
    size_t pktlen =strlen(sendata);
    sendpacket.len = htonl(pktlen);
    ssize_t sendLen = writen(clientSocket, &sendpacket, pktlen+5);
    printf("senddata = %s\n",sendata);
    
    // 接收数据
    //    char *buf[1024];
    //    ssize_t recvLen = recv(clientSocket, buf, sizeof(buf), 0);
    //    ssize_t recvLen = read(clientSocket, buf, sizeof(buf));
    //    NSString *recvStr = [[NSString alloc] initWithBytes:buf length:recvLen encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@",recvStr);
 ////////// 这里简化处理，为了使得代码不那么多，不加判断了
    tmis_packet_t recvpacket;
    memset(&recvpacket, 0, sizeof(recvpacket));
    readn(clientSocket, &recvpacket, 5);
    size_t dataLen = ntohl(recvpacket.len);
    ssize_t recvLen = readn(clientSocket,  recvpacket.buf, dataLen);
    
    //NSString *recvStr = [[NSString alloc] initWithBytes:tt.buf length:recvLen encoding:NSUTF8StringEncoding];
    //NSLog(@"%@",recvStr);
    //NSLog(@"%d",tt.flag);
    printf("recvdata = %s\n",recvpacket.buf);
    
//////////   解密数据，并且生成会话密钥
    unsigned char bytes_Li[4096]={0};
    hex2bytes(recvpacket.buf, strlen(recvpacket.buf), bytes_Li);
    
////////// 客户端接着干活
    char str_Li[4096]={0};
    aes_decrypt(bytes_Li,(unsigned char *)str_md5_k1,(unsigned char *)str_Li);
    printf("str_Li = %s\n",str_Li);
    //// 1.分割字符串
    char str_IDi[1024]={0}; // 和注册的时候str_id一样
    char str_Rs[1024]={0};
    char str_Ji[1024]={0};
    char str_t2[1024]={0};
    
    char *p = strtok(str_Li,split_char_key_agreement);
    if(p) strcpy(str_IDi,p);
    p = strtok(NULL,split_char_key_agreement);
    if(p) strcpy(str_Rs,p);
    p = strtok(NULL,split_char_key_agreement);
    if(p) strcpy(str_Ji,p);
    p = strtok(NULL,split_char_key_agreement);
    if(p) strcpy(str_t2,p);
    
    // 比较时间是否超时
//    time_t t2 =  [self string2time:str_t2];
//    time_t t2_2 = time(NULL);
   
//    string2time(str_t2, &t2);
//    if(t2_2-t2>120) { printf("超时了。。。\n"); return -2; }
//    else printf("没有超时。。。\n");
    
    //// 2. 恢复 Rs
    element_t element_Rs,element_Ji;
    
    element_init_G1(element_Rs,pairing);
    element_init_G1(element_Ji,pairing);
    
    element_set_str(element_Rs,str_Rs,10);
    element_mul(element_Ji,element_rc,element_Ai);
    element_mul(element_Ji,element_Ji,element_Rs);
    
    //// 3. 比较Ji
    char str_Ji2[1024]={0};
    element_snprint(str_Ji2,sizeof(str_Ji2),element_Ji);
    if(strcmp(str_Ji2,str_Ji)==0) printf("服务器端验证通过。。。\n");
    else { printf("服务器端验证失败。。。。\n");return -2; }
    
    ///// 4.计算sk
    len1=strlen(str_Ji2);
    len2=strlen(str_t1);
    len3=strlen(str_t2);
    char *CONSTR4 = (char *)malloc(sizeof(char)*(len1+len2+len3+1));
    memset(CONSTR4,0,len1+len2+len3+1);
    strncpy(CONSTR4,str_Ji2,len1);
    strncpy(CONSTR4+len1,str_t1,len2);
    strncpy(CONSTR4+len1+len2,str_t2,len3);
    
    unsigned char bytes_sk[50] = {0};
    md5((unsigned char*)CONSTR4, bytes_sk);
//    printhex(bytes_sk,16);
    char str_sk[50]={0};
    len1 = get_length(bytes_sk);
    bytes2hex(bytes_sk, len1, str_sk);
    char session_key[20] = {0};
    strncpy(session_key,str_sk,16);
    printf("%s\n",session_key);
    strcat(str_session_key, session_key);
    
    
    //// 释放内存
    free(CONSTR);
    free(CONSTR2);
    free(CONSTR3);
    free(CONSTR4);
    mpz_clear(mpz_temp1);
    mpz_clear(mpz_res);
    mpz_clear(mpz_Ci);
    mpz_clear(mpz_HPWi);
    mpz_clear(mpz_Bi);
    mpz_clear(mpz_Ai);
    element_clear(element_P);
    element_clear(elemetn_secret_key);
    element_clear(element_public_key);
    element_clear(element_Rc);
    element_clear(element_rc);
    element_clear(element_k1);
    element_clear(element_Ai);
    element_clear(element_Rs);
    element_clear(element_Ji);
    
    return 0;
}

-(void)getParam
{
    // 获得用户名和密码
    NSString *userid = self.uName.text;
    NSString *userpw = self.uPwd.text;
    // 获得注册参数
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *Bi = [userDefaults stringForKey:@"Bi"];
    NSString *Ci = [userDefaults stringForKey:@"Ci"];
    NSString *m_param = [userDefaults stringForKey:@"m"];
    NSString *b = [userDefaults stringForKey:@"b"];
    NSString *pkey = [userDefaults stringForKey:@"public_key"];
    // 简单打印
    NSLog(@"Bi = %@",Bi);
    NSLog(@"Ci = %@",Ci);
    NSLog(@"m = %@",m_param);
    NSLog(@"b = %@",b);
    NSLog(@"public_key = %@",pkey);
    
    // 转换成字符串
    strcpy(str_id, userid.UTF8String);
    strcpy(str_pw, userpw.UTF8String);
    strcpy(str_Bi,Bi.UTF8String);
    strcpy(str_Ci, Ci.UTF8String);
    strcpy(str_m, m_param.UTF8String);
    strcpy(str_b, b.UTF8String);
    strcpy(public_key, pkey.UTF8String);
    
}

#pragma mark - 网络实现部分
//建立连接
- (void)connectToServer:(NSString *)ip port:(int)port {
    clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == clientSocket) {
        XBLog(@"客户端socket创建失败");
        return;
    }
   
    
    struct sockaddr_in addr;
    /* 填写sockaddr_in结构*/
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
//    inet_pton(AF_INET, ip.UTF8String, &addr.sin_addr.s_addr);
    addr.sin_addr.s_addr = inet_addr(ip.UTF8String);
    
    int connectResult = connect(clientSocket, (const struct sockaddr *)&addr, sizeof(addr));
    if (connectResult == 0) {
        XBLog(@"客户端connect成功!");
    } else {
        XBLog(@"客户端connect失败，errno=%d",errno);
    }
    
    NSString* msg = @"xiangbin is a good boy? yes yes";
    const char *str = msg.UTF8String;
//    发送数据
//    ssize_t sendLen = send(clientSocket, str, strlen(str), 0);
//    ssize_t sendLen = write(clientSocket, str, strlen(str));
//    /** 发送的数据包相关信息 */
//    typedef struct tmis_packet
//    {
//        unsigned int len;                ///< 此次发送数据的长度
//        char flag;                              ///< 此次发送数据的类型 ，协商密钥的，安全通信的
//        char buf[BUFLEN];                  ///< 此次发送的数据
//    }tmis_packet_t;
    
    tmis_packet_t t;
    memset(&t, 0, sizeof(t));
    t.flag = 1;
    strcpy(t.buf , str);
    size_t datalen1 =strlen(str);
    t.len = htonl(datalen1);
   ssize_t sendLen = writen(clientSocket, &t, datalen1+5);

    
    // 接收数据
//    char *buf[1024];
//    ssize_t recvLen = recv(clientSocket, buf, sizeof(buf), 0);
//    ssize_t recvLen = read(clientSocket, buf, sizeof(buf));
//    NSString *recvStr = [[NSString alloc] initWithBytes:buf length:recvLen encoding:NSUTF8StringEncoding];
//    NSLog(@"%@",recvStr);
    tmis_packet_t tt;
    memset(&tt, 0, sizeof(tt));
    readn(clientSocket, &tt, 5);
    size_t dataLen = ntohl(tt.len);
    
    ssize_t recvLen = readn(clientSocket,  tt.buf, dataLen);
    NSString *recvStr = [[NSString alloc] initWithBytes:tt.buf length:recvLen encoding:NSUTF8StringEncoding];
    NSLog(@"%@",recvStr);
    NSLog(@"%d",tt.flag);
    
    
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

#pragma mark - 测试部分
- (void)test1{
    unsigned char in[30] = "xiangbin is a good boy!";
    unsigned char key[17] = "0123456789123456";
    unsigned char out[100];
    unsigned char out2[100];
    unsigned char out3[100];
    char outStr[100]={0};
    
    //int aes_decrypt(const char* in, const char* key, char* out)
    //int aes_decrypt(const char* in, const char* key, char* out)
    NSLog(@"测试aes....\n");
    memset(out,0,sizeof(out));
    memset(out2,0,sizeof(out2));
    aes_encrypt(in,key,out);
    // int bytes2hex(const unsigned char* in, const int len, char *out);
    bytes2hex(out, strlen((char *)out), outStr);
    
    NSString *s1 = [[NSString alloc] initWithBytes:outStr length:strlen(outStr) encoding:NSUTF8StringEncoding];
    
    
    NSLog(@"aes加密输出1：%@\n",s1 );
    
    // int hex2bytes(const char* in, int len,unsigned char* out);
    memset(out3,0,sizeof(out3));
    hex2bytes(outStr,strlen(outStr),out3);
    
    aes_decrypt(out3,key,out2);
    NSString *s2 = [[NSString alloc] initWithBytes:out2 length:strlen(out2) encoding:NSUTF8StringEncoding];
    
    NSLog(@"aes解密输出：%@\n",s2);
}

- (void) test2{
    unsigned char in[30] = "xiangbin is a good boy!";
    unsigned char out[100];
    char outStr[100]={0};
    
    
    
    //int md5(const unsigned char* in, unsigned char* out)
    NSLog(@"\n测试md5....\n");
    memset(out,0,sizeof(out));
    md5(in, out);
    bytes2hex(out, strlen((char *)out), outStr);
    NSString *s1 = [[NSString alloc] initWithBytes:outStr length:strlen(outStr) encoding:NSUTF8StringEncoding];
    
    
    NSLog(@"md5加密输出：%@",s1);
    
    
    //int sha1(const unsigned char* in, unsigned char* out);
    NSLog(@"\n测试sha1...\n");
    memset(out,0,sizeof(out));
    sha1(in, out);
    bytes2hex(out, strlen((char *)out), outStr);
    NSString *s2 = [[NSString alloc] initWithBytes:outStr length:strlen(outStr) encoding:NSUTF8StringEncoding];
    NSLog(@"sha1加密输出：%@",s2);
    
}
- (IBAction)click:(id)sender {
    [self test3];
}

-(void)test3{
    unsigned char in[30] = "xiangbin is a good boy!";
    unsigned char out[100];
    char outStr[100]={0};
    
    //int md5(const unsigned char* in, unsigned char* out)
    NSLog(@"\n测试md5....\n");
    memset(out,0,sizeof(out));
    md5(in, out);
    bytes2hex(out, strlen((char *)out), outStr);
    NSString *s1 = [[NSString alloc] initWithBytes:outStr length:strlen(outStr) encoding:NSUTF8StringEncoding];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:s1 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    // 弹出对话框
    [self presentViewController:alert animated:true completion:nil];
    
    
}

@end
