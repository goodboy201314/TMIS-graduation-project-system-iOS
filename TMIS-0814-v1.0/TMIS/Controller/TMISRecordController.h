//
//  TMISRecordController.h
//  TMIS
//
//  Created by xiangbin on 2018/7/17.
//  Copyright © 2018年 xiangbin1207. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TMISRecordController : UITableViewController
/**  用户名  */
@property (nonatomic,copy) NSString* uNamestr;

/**  客户端连接的套接字  */
@property (nonatomic,assign) int clientfd;

/**  sessionkey  */
@property (nonatomic,copy) NSString* sessionKey;
@end
