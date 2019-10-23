//
//  ViewController.m
//  FDVideoEdit
//
//  Created by 非道 on 2019/10/23.
//  Copyright © 2019 feidao. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import "FDVideoManager.h"


#define SCREEN_RECT [UIScreen mainScreen].bounds
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define ButtonTag 0xDDDDDD
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self _initSubViews];
}

#pragma mark - _initSubViews
- (void)_initSubViews
{
    NSArray *array = @[@"裁剪播放"];
    NSInteger count = array.count;
    CGFloat buttonWidth = 80.0;
    CGFloat buttonHeight = 80.0;
    CGFloat spaceWidth = (SCREEN_WIDTH - count * buttonWidth)/2;
    CGFloat top = 200.0;
    for (NSString *title in array) {
        NSInteger index = [array indexOfObject:title];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor redColor];
        button.frame = CGRectMake(spaceWidth*(index + 1) + index*buttonWidth, top, buttonWidth, buttonHeight);
        button.tag = ButtonTag + index;
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
    }
}

#pragma mark - button actions
- (void)clickButton:(UIButton *)sender
{
    NSInteger index = sender.tag - ButtonTag;
    switch (index) {
        case Cute:
        {
            FDVideoManager *manager = [FDVideoManager shareManager];
            AVURLAsset *asset = [manager getVideoAsset];
            NSString *filePath = [self pathInDocuments];
            [manager cuteVideoByStartTime:3.0 endTime:10.0 videoAsset:asset filePath:[NSURL fileURLWithPath:filePath] completion:^(NSURL * _Nonnull fileURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //创建播放器
                    AVPlayerViewController *player = [[AVPlayerViewController alloc]init];
                    player.player = [[AVPlayer alloc]initWithURL:fileURL];
                    
                    //模态出播放器
                    [self presentViewController:player animated:YES completion:nil];
                });
            }];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - private method
- (NSString*) pathInDocuments {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path0 = [paths objectAtIndex:0];
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    return [path0 stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",[dateFormatter stringFromDate:date]]];
}
@end
