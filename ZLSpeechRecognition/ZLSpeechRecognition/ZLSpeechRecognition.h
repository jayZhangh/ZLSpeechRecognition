//
//  ZLSpeechRecognition.h
//  ZLSpeechRecognition
//
//  Created by ZhangLiang on 2022/8/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZLSpeechRecognitionType) {
    ZLSpeechRecognitionTypeNormal = 0,
    ZLSpeechRecognitionTypeFile
};

@interface ZLSpeechRecognition : UIViewController
@property (nonatomic, copy) void (^textValueBlock)(NSString *textValue, ZLSpeechRecognitionType type);
@property (nonatomic, copy) void (^statusChangeBlock)(NSString *message);
- (void)recognizeLocalAudioFile:(NSString *)audioFile;
- (void)startRecoding;
- (void)stopRecording;
@end

NS_ASSUME_NONNULL_END
