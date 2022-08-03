//
//  ViewController.m
//  ZLSpeechRecognition
//
//  Created by ZhangLiang on 2022/8/3.
//

#import "ViewController.h"
#import "ZLSpeechRecognition/ZLSpeechRecognition.h"

@interface ViewController ()
@property (nonatomic, strong) ZLSpeechRecognition *speechRecognition;
@property (weak, nonatomic) IBOutlet UILabel *textLab;
- (IBAction)startAction:(id)sender;
- (IBAction)stopAction:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __weak typeof(self) wekself = self;
    self.speechRecognition = [[ZLSpeechRecognition alloc] init];
    self.speechRecognition.textValueBlock = ^(NSString * _Nonnull textValue, ZLSpeechRecognitionType type) {
        NSLog(@"%ld - %@", type, textValue);
        wekself.textLab.text = textValue;
    };
    
    self.speechRecognition.statusChangeBlock = ^(NSString *message) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
        [wekself presentViewController:alertController animated:YES completion:nil];
    };
}

- (IBAction)stopAction:(id)sender {
    [self.speechRecognition stopRecording];
}

- (IBAction)startAction:(id)sender {
    [self.speechRecognition startRecoding];
}

@end
