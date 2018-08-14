//
//  TMISRecordController.m
//  TMIS
//
//  Created by xiangbin on 2018/7/17.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import "TMISRecordController.h"
#import "TMISRecordCell.h"
#import "TMISRecordData.h"
#import "tmis_enc_denc.h"
#import "TMISIO.h"

@interface TMISRecordController ()
/**  记录数组  */
@property (nonatomic,strong) NSArray* recordDatasArray;

@end

@implementation TMISRecordController
// 数据的懒加载
- (NSArray *)recordDatasArray
{
    if(!_recordDatasArray)
    {
        /**
         @property (nonatomic,copy) NSString* tmis_time;
         @property (nonatomic,copy) NSString* tmis_doctor;
         @property (nonatomic,copy) NSString* tmis_symptom;
         @property (nonatomic,copy) NSString* tmis_feedback;
         @property (nonatomic,assign) float cell_height;
         **/
        NSArray *array = [self getRecordFromServer];
//        NSDictionary *dict1 = @{
//                                @"tmis_time" : @"2010-09-21",
//                                @"tmis_doctor" : @"张医生",
//                                @"tmis_symptom" : @"腹泻，大概每天10-20次，呕吐",
//                                @"tmis_feedback" : @"急性肠胃炎"
//                                };
//        
//        NSDictionary *dict2 = @{
//                                @"tmis_time" : @"2010-10-21",
//                                @"tmis_doctor" : @"李医生",
//                                @"tmis_symptom" : @"腹泻，大概每天10-20次，呕吐腹泻，大概每天10-20次，呕吐腹泻",
//                                @"tmis_feedback" : @"肠胃炎"
//                                };
//        
//        NSArray *array = @[dict1,dict2];
        
        // 从数据数组中恢复创建数据模型
        NSMutableArray *recordsArray = [NSMutableArray array];
        for (NSDictionary *dict in array) {
            TMISRecordData *s = [TMISRecordData initWithDict:dict];
            [recordsArray addObject:s];
        }
        _recordDatasArray = recordsArray;
    }
    
    return _recordDatasArray;
}

-(NSArray *)getRecordFromServer
{
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
    NSString *sendateStr = self.uNamestr;
    char sendata[100]={0};
    strcpy(sendata, sendateStr.UTF8String);
    
    tmis_packet_t sendpacket;
    memset(&sendpacket, 0, sizeof(sendpacket));
    sendpacket.flag = 2;
    strcpy(sendpacket.buf , sendata);
    size_t pktlen =strlen(sendata);
    sendpacket.len = htonl(pktlen);
    ssize_t sendLen = writen(self.clientfd, &sendpacket, pktlen+5);
    printf("In RecordController: sendata = %s\n",sendata);
    
    // 接收数据
    //    char *buf[1024];
    //    ssize_t recvLen = recv(clientSocket, buf, sizeof(buf), 0);
    //    ssize_t recvLen = read(clientSocket, buf, sizeof(buf));
    //    NSString *recvStr = [[NSString alloc] initWithBytes:buf length:recvLen encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@",recvStr);
////////// 这里简化处理，为了使得代码不那么多，不加判断了
    tmis_packet_t recvpacket;
    memset(&recvpacket, 0, sizeof(recvpacket));
    readn(self.clientfd, &recvpacket, 5);
    size_t dataLen = ntohl(recvpacket.len);
    ssize_t recvLen = readn(self.clientfd,  recvpacket.buf, dataLen);
    
    //NSString *recvStr = [[NSString alloc] initWithBytes:tt.buf length:recvLen encoding:NSUTF8StringEncoding];
    //NSLog(@"%@",recvStr);
    //NSLog(@"%d",tt.flag);
    printf("recvdata = %s\n",recvpacket.buf);
    
    NSMutableArray *dataArr = [NSMutableArray array];
    // 如果收到的信息不是医疗记录
    if(recvpacket.flag!=2) return dataArr;
    
    unsigned char bytes_server_back[4096*5]={0};
    hex2bytes(recvpacket.buf, strlen(recvpacket.buf), bytes_server_back);
//////////  解密
    char str_server_back[4096*5]={0};
    aes_decrypt(bytes_server_back, self.sessionKey.UTF8String, str_server_back);
    printf("str_server_back = %s\n",str_server_back);
    
    NSString *ser_back = [NSString stringWithUTF8String:str_server_back];
   // NSString*ser_back2 = [[NSString alloc] initWithBytes:str_server_back length:strlen(str_server_back) encoding:NSUTF8StringEncoding];
    NSArray *records = [ser_back componentsSeparatedByString:@"AAAA"];
//    NSLog(@"len = %ld, array=%@,%@",records.count,records,records[0]);
    
    // 最后一个数据为空，要摄取
    for(int i=0;i<records.count-1;i++)
    {
        NSArray *rfields = [records[i] componentsSeparatedByString:@"AA"];
//        NSLog(@"len = %ld, array=%@,%@",rfields.count,rfields,rfields[0]);
        NSDictionary *dict = @{
                                @"tmis_time" : rfields[0],
                                @"tmis_doctor" : rfields[1],
                                @"tmis_symptom" : rfields[2],
                                @"tmis_feedback" : rfields[3],
                                @"enc_string":[NSString stringWithUTF8String:recvpacket.buf]
                                };
        
        [dataArr addObject:dict];
    }
    
    
    return dataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *str = [NSString stringWithFormat:@"%@ 的医疗记录",self.uNamestr];
    self.title = str;
    
    //self.navigationItem.leftBarButtonItem= [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc] init]];
    self.navigationItem.leftBarButtonItem= [[UIBarButtonItem alloc] initWithTitle:@"<返回" style:UIBarButtonItemStylePlain target:self action:@selector(record_back)];
    
    NSLog(@"In recordController:%@",self.sessionKey);
}

- (void)record_back
{
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recordDatasArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 1.创建cell
    TMISRecordCell *cell =[TMISRecordCell cellWithTableView:tableView];
    // 2.给cell赋模型的值
    cell.recordData = self.recordDatasArray[indexPath.row];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%f", [self.recordDatasArray[indexPath.row] cell_height]);
    return [self.recordDatasArray[indexPath.row] cell_height];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 500;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
