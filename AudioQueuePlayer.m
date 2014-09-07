//
//  AudioQueuePlayer.m
//  AudioQueuePlayer
//
//  Created by rneuo on 2014/09/04.
//  Copyright (c) 2014年 rneuo. All rights reserved.
//

#import "AudioQueuePlayer.h"


@implementation AudioQueuePlayer

// コールバック関数
static void AQOutputCallback(void *userData,
                             AudioQueueRef audioQueueRef,
                             AudioQueueBufferRef audioQueueBufferRef) {

  AudioQueuePlayer *player = (__bridge AudioQueuePlayer*)userData;
  [player audioQueueOutputWithQueue:audioQueueRef queueBuffer:audioQueueBufferRef];
}

- (id)initWithFilepath:(NSURL *)path {
  indexPacket = 0;
  
  filepath = path;
  
  // オーディオキューを作成する
  [self createAudioQueue];
  
  // 再生の事前準備をする
  [self prepareToPlay];
  
  return self;
}

-(UInt32)currentIndex {
  return indexPacket;
}

- (void)createAudioQueue {
  UInt32 propertySize;
  
  // 2 再生するオーディオファイルを読み込み権限で開く
  AudioFileOpenURL((CFURLRef)CFBridgingRetain(filepath),
                   kAudioFileReadPermission,
                   0,
                   &inAudioFile);
  
  // 3 オーディオデータフォーマットの情報を取得する
  propertySize = sizeof(audioDataFormat); // AudioStreamBasicDescriptionのサイズ
  AudioFileGetProperty(inAudioFile,
                       kAudioFilePropertyDataFormat, // AudioStreamBasicDescriptionのオーディオデータフォーマットを指定
                       &propertySize,                // バッファに記述されるAudioStreamBasicDescriptionのバイト数がセットされる
                       &audioDataFormat);            // 取得するオーディオファイルのAudioStreamBasicDescriptionがセットされる
  
  // 4 再生用のオーディオキューオブジェクトを作成する
  AudioQueueNewOutput(&audioDataFormat,        // AudioStreamBasicDescription
                      AQOutputCallback,        // AudioQueueOutputCallback
                      (void *)CFBridgingRetain(self), // AudioQueueOutputCallbackの第一引数に渡される
                      CFRunLoopGetCurrent(),
                      kCFRunLoopCommonModes,
                      0,
                      &audioQueue);
}

- (void)prepareToPlay {
  UInt32 propertySize;
  
  // パケットの最大バイト数を取得
  UInt32 maxPacketSize;
  propertySize = sizeof(maxPacketSize);
  AudioFileGetProperty(inAudioFile,
                       kAudioFilePropertyPacketSizeUpperBound,
                       &propertySize,
                       &maxPacketSize);
  
  // 毎秒のパケット数
  Float64 numPacketsPerSecond;
  numPacketsPerSecond = audioDataFormat.mSampleRate / audioDataFormat.mFramesPerPacket;

  UInt32 bufferSize;
  bufferSize = numPacketsPerSecond * maxPacketSize * kNumberBuffers;

  numPacketsToRead = numPacketsPerSecond * kBufferSeconds;
  
  propertySize = sizeof(maxNumPackets);
  AudioFileGetProperty(inAudioFile,
                       kAudioFilePropertyAudioDataPacketCount,
                       &propertySize,
                       &maxNumPackets);
  
  audioPacketDesc = malloc(numPacketsToRead * sizeof(AudioStreamPacketDescription));
  
  // バッファを作成
  for (int i = 0; i < kNumberBuffers; i++) {
    AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioBuffers[i]);
  }

}

- (void) audioQueueOutputWithQueue:(AudioQueueRef)audioQueueRef
                       queueBuffer:(AudioQueueBufferRef)audioQueueBufferRef {
  
  UInt32 numBytes;
  UInt32 numPackets = numPacketsToRead;

  AudioFileReadPackets(inAudioFile,
                       NO,
                       &numBytes,
                       audioPacketDesc,
                       indexPacket,
                       &numPackets,
                       audioQueueBufferRef->mAudioData);

  if (numPackets > 0) {
    audioQueueBufferRef->mAudioDataByteSize = numBytes;
    AudioQueueEnqueueBuffer(audioQueueRef,
                            audioQueueBufferRef,
                            numPackets,
                            audioPacketDesc);
    // 次のパケットを読み込むようにする
    indexPacket += numPackets;
    NSLog(@"v: %lu", (long)audioPacketDesc->mStartOffset);
    NSLog(@"indexPacket: %lu", (long)indexPacket);
    if (indexPacket + numPackets >= maxNumPackets) {
      indexPacket = 0;
    }
  }

  UInt32 valueSize = sizeof(playStatus);
  AudioQueueGetProperty(audioQueueRef, kAudioQueueProperty_IsRunning, &playStatus, &valueSize);
}


-(void)play {
  if (playStatus == 0) {
    for(int i=0; i<kNumberBuffers; i++){
      [self audioQueueOutputWithQueue:audioQueue queueBuffer:audioBuffers[i]];
    }
    
    AudioQueueStart(audioQueue, nil);
  }
}

@end
