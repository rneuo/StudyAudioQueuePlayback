//
//  AudioQueuePlayer.h
//  AudioQueuePlayer
//
//  Created by rneuo on 2014/09/04.
//  Copyright (c) 2014年 rneuo. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kNumberBuffers 3
#define kBufferSeconds 0.5

@interface AudioQueuePlayer : NSObject
{
  NSURL                        *filepath;
  AudioStreamBasicDescription  audioDataFormat;
  AudioQueueRef                audioQueue;
  AudioQueueBufferRef          audioBuffers[kNumberBuffers];
  AudioFileID                  inAudioFile;
  AudioStreamPacketDescription *audioPacketDesc;
  UInt32                       indexPacket;
  UInt64                       maxNumPackets;
  UInt32                       numPacketsToRead;
  UInt32                       playStatus;
}

- (id)initWithFilepath:(NSURL *)path;
- (void)play;

@end
