//
//  TableViewController.h
//  RadicalCodeChallenge
//
//  Created by Ryan Lu on 6/2/15.
//  Copyright (c) 2015 Ryan Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewController : UITableViewController<UITableViewDataSource>
- (void)showFullScreenPhoto:(NSInteger *)currentIndex;
@end
