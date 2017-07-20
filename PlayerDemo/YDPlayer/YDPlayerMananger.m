//
//  YDPlayerMananger.m
//  GMAppStationKit
//
//  Created by 侯亚迪 on 17/6/19.
//  Copyright © 2017年 杭州魔品科技股份有限公司. All rights reserved.
//

#import "YDPlayerMananger.h"

NSString * const YDPlayerDidStartPlayNotification = @"YDPlayerDidStartPlayNotification";

@interface YDPlayerMananger ()
@property (nonatomic, strong) id timeObserver; // 监控播放进度的观察者

@end

@implementation YDPlayerMananger

#pragma mark - 生命周期

- (instancetype)init
{
    if (self = [super init]) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:YES error:nil];
        self.player = [[AVPlayer alloc] init];
        [self addNotificationAndObserver];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        [self replaceCurrentItemWithURL:url];
    }
    return self;
}

+ (instancetype)shareManager
{
    static YDPlayerMananger *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)dealloc
{
    [self removeNotificationAndObserver];
}

#pragma mark - 公开方法

- (void)showPlayerInView:(UIView *)view withFrame:(CGRect)frame
{
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _playerLayer.frame = frame;
    _playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [view.layer addSublayer:_playerLayer];
}

- (void)replaceCurrentItemWithURL:(NSURL *)url
{
    // 移除当前观察者
    if (_currentItem) {
        [_currentItem removeObserver:self forKeyPath:@"status"];
        [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
    _currentItem = [[AVPlayerItem alloc] initWithURL:url];
    [self.player replaceCurrentItemWithPlayerItem:_currentItem];
    
    // 重新添加观察者
    [_currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)playWithUrl:(NSString *)urlStr
{
    [self replaceCurrentItemWithURL:[NSURL URLWithString:urlStr]];
    [self play];
}

- (void)play
{
    [self.player play];
    self.playStatus = YDPlayerStatusPlaying;
    // 发起开始播放的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:YDPlayerDidStartPlayNotification object:_player];
}

- (void)pause
{
    [self.player pause];
    self.playStatus = YDPlayerStatusPausing;
}

- (void)stop
{
    [self.player pause];
    [_currentItem cancelPendingSeeks];
    self.playStatus = YDPlayerStatusFinished;
}

- (void)seekToTime:(CGFloat)time
{
    [_currentItem seekToTime:CMTimeMakeWithSeconds(time, 1.0) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark - 私有方法

// 添加通知、观察者
- (void)addNotificationAndObserver
{
    // 添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    // 添加打断播放的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionComing:) name:AVAudioSessionInterruptionNotification object:nil];
    // 添加插拔耳机的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
    // 添加观察者监控播放器状态
    [self addObserver:self forKeyPath:@"playStatus" options:NSKeyValueObservingOptionNew context:nil];
    // 添加观察者监控进度
    __weak typeof(self) weakSelf = self;
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (strongSelf.currentPlayTimeCallBack) {
            float currentPlayTime = (double)strongSelf.currentItem.currentTime.value / strongSelf.currentItem.currentTime.timescale;
            strongSelf.currentPlayTimeCallBack(strongSelf.player, currentPlayTime);
        }
    }];
}

// 移除通知、观察者
- (void)removeNotificationAndObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"playStatus"];
    [_player removeTimeObserver:_timeObserver];
    if (_currentItem) {
        [_currentItem removeObserver:self forKeyPath:@"status"];
        [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
}

#pragma mark - 观察者

// 观察者
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        
        if (status == AVPlayerStatusReadyToPlay) {
            // 获取视频长度
            if (self.currentItemDurationCallBack) {
                CGFloat duration = CMTimeGetSeconds(_currentItem.duration);
                self.currentItemDurationCallBack(_player, duration);
            }
            
        } else if (status == AVPlayerStatusFailed) {
            self.playStatus = YDPlayerStatusFailed;
        } else {
            self.playStatus = YDPlayerStatusUnknown;
        }
        
    } else if ([keyPath isEqualToString:@"playStatus"]) {
        
        if (self.playStatusChangeCallBack) {
            self.playStatusChangeCallBack(_player, _playStatus);
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        // 计算缓冲总进度
        NSArray *loadedTimeRanges = [_currentItem loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval loadedTime = startSeconds + durationSeconds;

        if (self.playStatus == YDPlayerStatusPlaying && self.player.rate <= 0) {
            self.playStatus = YDPlayerStatusLoading;
        }
        
        // 卡顿时缓冲完成后自动播放
        if (self.playStatus == YDPlayerStatusLoading) {
            NSTimeInterval currentTime = self.player.currentTime.value / self.player.currentTime.timescale;
            if (loadedTime > currentTime + 5) {
                [self play];
            }
        }
        
        if (self.currentLoadedTimeCallBack) {
            self.currentLoadedTimeCallBack(_player, loadedTime);
        }
    }
}

#pragma mark - 通知

// 播放完成通知
- (void)playbackFinished:(NSNotification *)notification
{
    AVPlayerItem *playerItem = (AVPlayerItem *)notification.object;
    if (playerItem == _currentItem) {
        self.playStatus = YDPlayerStatusFinished;
    }
}

// 插拔耳机通知
- (void)routeChanged:(NSNotification *)notification
{
    NSDictionary *dic = notification.userInfo;
    int changeReason = [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    // 旧输出不可用
    if (changeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription = dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription = [routeDescription.outputs firstObject];
        // 原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}

// 来电、闹铃打断播放通知
- (void)interruptionComing:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    AVAudioSessionInterruptionType type = [userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
    }
}

@end
