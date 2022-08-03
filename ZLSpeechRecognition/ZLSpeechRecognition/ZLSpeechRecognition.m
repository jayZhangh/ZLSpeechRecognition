//
//  ZLSpeechRecognition.m
//  ZLSpeechRecognition
//
//  Created by ZhangLiang on 2022/8/3.
//

#import "ZLSpeechRecognition.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface ZLSpeechRecognition () <SFSpeechRecognizerDelegate>
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@end

@implementation ZLSpeechRecognition

- (void)authorization {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = nil;
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    message = @"语音识别未授权";
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    message = @"用户未授权使用语音识别";
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    message = @"语音识别在这台设备上受到限制";
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    message = @"可以开始使用语音识别功能";
                    break;
                default:
                    break;
            }
            
            if (self.statusChangeBlock) {
                self.statusChangeBlock(message);
            }
        });
    }];
}

#pragma mark - property
- (AVAudioEngine *)audioEngine {
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    
    return _audioEngine;
}

- (SFSpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {
        // 要为语音识别对象设置语音，这里设置的是中文
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        
        _speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
        _speechRecognizer.delegate = self;
    }
    
    return _speechRecognizer;
}

/** 识别本地音频文件 */
- (void)recognizeLocalAudioFile:(NSString *)audioFile {
    [self authorization];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer *localRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    NSURL *url = [[NSBundle mainBundle] URLForResource:audioFile withExtension:nil];
    if (!url) return;
    SFSpeechURLRecognitionRequest *res = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSString *errMsg = [NSString stringWithFormat:@"语音识别解析失败, %@", error];
            if (self.statusChangeBlock) {
                self.statusChangeBlock(errMsg);
            }
        } else {
            NSString *resultString = result.bestTranscription.formattedString;
            if (self.textValueBlock) {
                self.textValueBlock(resultString, ZLSpeechRecognitionTypeFile);
            }
        }
    }];
}

- (void)stopRecording {
    [self.audioEngine stop];
    if (_recognitionRequest) {
        [_recognitionRequest endAudio];
    }
    
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
}

- (void)startRecoding {
    [self authorization];
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = [self.audioEngine inputNode];
    
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) wekself = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            NSString *resultString = result.bestTranscription.formattedString;
            if (self.textValueBlock) {
                self.textValueBlock(resultString, ZLSpeechRecognitionTypeNormal);
            }
            
            isFinal = result.isFinal;
        }
        
        if (error || isFinal) {
            [wekself.audioEngine stop];
            [inputNode removeTapOnBus:0];
            wekself.recognitionTask = nil;
            wekself.recognitionRequest = nil;
//            NSLog(@"---停止语音识别服务---");
            if (self.statusChangeBlock) {
                self.statusChangeBlock(@"停止语音识别服务");
            }
        }
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    // 在添加tap之前先移除上一个 不然可能报错
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        if (wekself.recognitionRequest) {
            [wekself.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
}

#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
//    if (available) {
//        NSLog(@"开始录音");
//    } else {
//        NSLog(@"语音识别不可用");
//    }
}

- (void)dealloc {
    NSLog(@"ZLSpeechRecognition - dealloc.");
}

@end
