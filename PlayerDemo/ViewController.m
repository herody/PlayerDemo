//
//  ViewController.m
//  PlayerDemo
//
//  Created by 侯亚迪 on 17/7/12.
//  Copyright © 2017年 杭州魔品科技. All rights reserved.
//

#import "ViewController.h"
#import "YDPlayerManager.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UISlider *playProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *loadProgress;
@property (weak, nonatomic) IBOutlet UILabel *curTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@property (nonatomic, strong) YDPlayerManager *manager;
@property (nonatomic, assign) CGFloat totalTime;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.playProgress setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [self addVideoPlayer];
}

- (void)addVideoPlayer
{
//    NSURL *url = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"如烟-五月天" ofType:@"mp3"]];
    self.manager = [[YDPlayerManager alloc] initWithURL:url];
    
    //展示播放器界面
    [_manager showPlayerInView:self.playerView withFrame:self.playerView.bounds];
    
    //播放总时长回调
    __weak typeof(self) weakSelf = self;
    [_manager setCurrentItemDurationCallBack:^(AVPlayer *player, CGFloat duration) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.totalTime = duration;
        strongSelf.totalTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)duration / 60, (int)duration % 60];
    }];
    
    //播放进度回调
    [_manager setCurrentPlayTimeCallBack:^(AVPlayer *player, CGFloat time) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.curTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)time / 60, (int)time % 60];
        if (strongSelf.totalTime) {
            strongSelf.playProgress.value = time / strongSelf.totalTime;
        }
    }];
    
    //播放器状态改变回调
    [_manager setPlayStatusChangeCallBack:^(AVPlayer *player, YDPlayerStatus status) {
        __strong typeof(self) strongSelf = weakSelf;
        if (status == YDPlayerStatusPlaying || status == YDPlayerStatusLoading) {
            strongSelf.playBtn.selected = YES;
        } else {
            strongSelf.playBtn.selected = NO;
        }
    }];
    
    //缓冲进度回调
    [_manager setCurrentLoadedTimeCallBack:^(AVPlayer *player, CGFloat time) {
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf.totalTime) {
            strongSelf.loadProgress.progress = time / strongSelf.totalTime;
        }
    }];
}

- (IBAction)handlePlay:(UIButton *)sender
{
    if (sender.selected) {
        [_manager pause];
    } else {
        [_manager play];
    }
}

- (IBAction)handleSeek:(UISlider *)sender
{
    [_manager seekToTime:sender.value * _totalTime];
}

@end
