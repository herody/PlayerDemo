//
//  YDPlayerMananger.h
//  GMAppStationKit
//
//  Created by 侯亚迪 on 17/6/19.
//  Copyright © 2017年 杭州魔品科技股份有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 播放器开始播放的通知
 当存在多个播放器，可使用该通知在其他播放器播放时暂停当前播放器
 */
extern NSString * const YDPlayerDidStartPlayNotification;

/**
 enum 播放器状态

 - YDPlayerStatusUnknown: 未知
 - YDPlayerStatusPlaying: 播放中
 - YDPlayerStatusLoading: 加载中
 - YDPlayerStatusPausing: 暂停中
 - YDPlayerStatusFailed: 播放失败
 - YDPlayerStatusFinished: 播放完成
 */
typedef NS_ENUM(NSInteger, YDPlayerStatus) {
    YDPlayerStatusUnknown,
    YDPlayerStatusPlaying,
    YDPlayerStatusLoading,
    YDPlayerStatusPausing,
    YDPlayerStatusFailed,
    YDPlayerStatusFinished
};


@interface YDPlayerManager : NSObject

/**
 播放器
 */
@property (nonatomic, strong) AVPlayer *player;

/**
 播放器layer层
 */
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

/**
 当前PlayerItem
 */
@property (nonatomic, strong) AVPlayerItem *currentItem;

/**
 播放器状态
 */
@property (nonatomic, assign) YDPlayerStatus playStatus;

/**
 Item总时长回调
 */
@property (nonatomic, copy) void(^currentItemDurationCallBack)(AVPlayer *player, CGFloat duration);

/**
 Item播放进度回调
 */
@property (nonatomic, copy) void(^currentPlayTimeCallBack)(AVPlayer *player, CGFloat time);

/**
 Item缓冲进度回调
 */
@property (nonatomic, copy) void(^currentLoadedTimeCallBack)(AVPlayer *player, CGFloat time);

/**
 Player状态改变回调
 */
@property (nonatomic, copy) void(^playStatusChangeCallBack)(AVPlayer *player, YDPlayerStatus status);


/**
 初始化方法
 
 @param url 播放链接
 @return YDPlayerMananger对象
 */
- (instancetype)initWithURL:(NSURL *)url;


/**
 创建单例对象

 @return YDPlayerMananger单例对象
 */
+ (instancetype)shareManager;


/**
 将播放器展示在某个View
 
 @param view 展示播放器的View
 */
- (void)showPlayerInView:(UIView *)view withFrame:(CGRect)frame;


/**
 替换PlayerItem

 @param url 需要播放的链接
 */
- (void)replaceCurrentItemWithURL:(NSURL *)url;


/**
 播放某个链接

 @param url 需要播放的链接
 */
- (void)playWithUrl:(NSURL *)url;


/**
 开始播放
 */
- (void)play;


/**
 暂停播放
 */
- (void)pause;


/**
 停止播放
 */
- (void)stop;


/**
 跳转到指定时间

 @param time 指定的时间
 */
- (void)seekToTime:(CGFloat)time;

@end
