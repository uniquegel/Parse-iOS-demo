//
//  TableViewController.m
//  RadicalCodeChallenge
//
//  Created by Ryan Lu on 6/2/15.
//  Copyright (c) 2015 Ryan Lu. All rights reserved.
//

#import <Parse/Parse.h>
#import "TableViewController.h"

@interface TableViewController ()
@property (retain) NSMutableArray  *array;
@property UIImageView *fullscreenView;
@property UIView *filter;
@property double filterAlpha;
@property NSInteger currentIndex;
@property NSInteger objectsOnParse;
@property  UIActivityIndicatorView *ai;
@end

@implementation TableViewController

- (void)viewDidLoad {

    /*
     cm.jpg -> Crystal Maiden
     
     dr.jpg -> Drow Ranger
     
     ls.jpg -> Life Stealer
     
     luna.jpg -> Luna
     
     sk.jpg -> Sand King
     
     
     */
    [super viewDidLoad];
    
    //Initialization
    self.filterAlpha = 0.8;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    //activity indicator initialization
    self.ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.ai.center = self.view.center;
    [self.view addSubview:self.ai];
    [self.ai startAnimating ];

    //query for parse
    PFQuery *query = [PFQuery queryWithClassName:@"Pics"];
    self.objectsOnParse = [query countObjects];
    
    //if there is nothing on parse then create locally, otherwise download from parse
    if (self.objectsOnParse == 0) {
        [self.ai stopAnimating];
        NSLog(@"No objects on parse, now initiate locally and store them on parse");
        NSDictionary *dicCM = @{
                                @"name": @"Crystal Maidan",
                                @"image": [UIImage imageNamed:@"cm.jpg"],
                                @"filename": @"cm.jpg"
                                };
        NSDictionary *dicDR = @{
                                @"name": @"Drow Ranger",
                                @"image": [UIImage imageNamed:@"dr.jpg"],
                                @"filename": @"dr.jpg"
                                };
        NSDictionary *dicLS = @{
                                @"name": @"Life Stealer",
                                @"image": [UIImage imageNamed:@"ls.jpg"],
                                @"filename": @"ls.jpg"
                                };
        NSDictionary *dicLuna = @{
                                  @"name": @"Luna",
                                  @"image": [UIImage imageNamed:@"luna.jpg"],
                                  @"filename": @"luna.jpg"
                                  };
        NSDictionary *dicSK = @{
                                @"name": @"Sand King",
                                @"image": [UIImage imageNamed:@"sk.jpg"],
                                @"filename": @"sk.jpg"
                                };
        self.array = [[NSArray alloc] initWithObjects:dicDR, dicCM, dicLuna, dicLS, dicSK, nil];
        
        //upload the pictures to parse
        for (int i=0; i<5; i++) {
            NSData* data = UIImageJPEGRepresentation([[self.array objectAtIndex:i] objectForKey:@"image"], 0.5);
            PFObject *picObject = [PFObject objectWithClassName:@"Pics"];
            picObject[@"name"] = [[self.array objectAtIndex:i] objectForKey:@"name"];
            picObject[@"filename"] = [[self.array objectAtIndex:i] objectForKey:@"filename"];
            PFFile *pic = [PFFile fileWithName:[[self.array objectAtIndex:i]
                                                objectForKey:@"filename"] data:data];
            picObject[@"image"] = pic;
            [picObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"Pictures Saved on Parse");
                }
                else{
                    // Error
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        }
    }
    else{
        NSMutableArray *picArray = [NSMutableArray array];
        NSLog(@"Found objects on parse! Data will be retreived!");
        //download all objects from parse
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSLog(@"Retrieved %lu objects from parse. " , (unsigned long)objects.count);
                for (int i=0; i<objects.count; i++) {
                    //                    UIImage *localImage;
                    PFFile *image = [[objects objectAtIndex:i] objectForKey:@"image"];
                    
                    if(image != nil)
                    {
                        //convert pffile into uiimage
                        [image getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                            UIImage *localImage = [UIImage imageWithData:imageData];
                            NSDictionary *dic = @{
                                                  @"name": [[objects objectAtIndex:i] objectForKey:@"name"],
                                                  @"image": localImage,
                                                  @"filename":[[objects objectAtIndex:i] objectForKey:@"filename"]
                                                  };
//                            UIImageView *iview = [[UIImageView alloc] initWithImage:[dic objectForKey:@"image"]];
//                            iview.frame = CGRectMake(20*i, 20*i, 100, 100);
//                            [self.view addSubview:iview];

                            [picArray addObject:dic];
                            if (picArray.count == 5) {
                                self.array = picArray;
                                [self.ai stopAnimating];
                                [self.tableView reloadData];
                            }
                        }];
                    }
                }
            } else {
                // Log details of the failure
                NSLog(@"Error: %@ %@", error, [error userInfo]);
            }
        }];
        
        
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return self.array.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //initialize cell
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

    //configure cell
    cell.imageView.image = [[self.array objectAtIndex:indexPath.row] objectForKey:@"image"];
    cell.textLabel.text = [[self.array objectAtIndex:indexPath.row] objectForKey:@"name"];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //when select a row, set the currentindex to the row index and show the full screen view
    self.currentIndex = indexPath.row;
    [self showFullScreenPhoto:indexPath.row];
}

- (void)showFullScreenPhoto:(NSInteger *)currentIndex {
    //a filter
    self.filter = [[UIView alloc] initWithFrame:self.view.frame];
    self.filter.backgroundColor = [UIColor blackColor];
    self.filter.alpha = self.filterAlpha;
    
    //the full screen view
    self.fullscreenView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0 , 375, 667) ];
    self.fullscreenView.contentMode = UIViewContentModeScaleAspectFit;
    self.fullscreenView.image = [[self.array objectAtIndex:currentIndex] objectForKey:@"image"];
    self.fullscreenView.userInteractionEnabled =YES;
    
    //swipe gestures
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeftRecognized:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.fullscreenView addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRightRecognized:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.fullscreenView addGestureRecognizer:swipeRight];
    
    //a back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    backButton.frame = CGRectMake(10, 10, 100, 50);
    [backButton setTitle:@"BACK" forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    
    //the image title
    UILabel *title= [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-100, 50, 200, 50)];
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.text =[[self.array objectAtIndex:currentIndex] objectForKey:@"name"];
    
    
    //configure the hierachy
    [self.fullscreenView addSubview:title];
    [self.fullscreenView addSubview:backButton];
        [self.view addSubview:self.filter];
    [self.view addSubview:self.fullscreenView];
    
    //animation
    self.filter.alpha = 0;
    self.fullscreenView.alpha = 0;
    [UIView animateWithDuration:0.6 animations:^{
        self.fullscreenView.alpha= 1;
            self.filter.alpha = self.filterAlpha;
    }];
    
}
- (void)swipeLeftRecognized: (UISwipeGestureRecognizer *) recognizer {
    if (self.currentIndex!=4) {
        self.currentIndex++;
    }
    else {
        self.currentIndex=0;
    }
    
    //animation
    [UIView animateWithDuration:0.6 animations:^{
        self.filter.alpha = 0;
        self.fullscreenView.alpha= 0;
    }
                     completion:^(BOOL finished) {
                         [self.fullscreenView removeFromSuperview];
                         [self showFullScreenPhoto:self.currentIndex];
                     }];
    
    
}

- (void)swipeRightRecognized: (UISwipeGestureRecognizer *) recognizer {
    
    if (self.currentIndex!=0) {
        self.currentIndex--;
    }
    else {
        self.currentIndex=4;
    }
    
    //animation
    [UIView animateWithDuration:0.6 animations:^{
        self.filter.alpha = 0;
        self.fullscreenView.alpha= 0;
    }
                     completion:^(BOOL finished) {
                         [self.fullscreenView removeFromSuperview];
                         [self showFullScreenPhoto:self.currentIndex];
                     }];
    
    
}

- (void)backButtonClicked {
    //animation, back to home tableview
    [UIView animateWithDuration:0.6 animations:^{
        self.filter.alpha = 0;
        self.fullscreenView.alpha= 0;
    }
                     completion:^(BOOL finished) {
                         [self.fullscreenView removeFromSuperview];
                     }];
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
