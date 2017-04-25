//
//  WQCodeScanner.m
//  CodeScanner
//
//  Created by wangyuxiang on 2017/3/27.
//  Copyright © 2017年 wangyuxiang. All rights reserved.
//

#import "WQCodeScanner.h"
#import <AVFoundation/AVFoundation.h>

@interface WQCodeScanner ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) BOOL isReading;

@property (nonatomic, assign) UIStatusBarStyle originStatusBarStyle;

@property (nonatomic, strong) UIImageView *lineImageView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end

@implementation WQCodeScanner

- (id)init {
    self = [super init];
    if (self) {
        self.scanType = WQCodeScannerTypeAll;
    }
    return self;
}

- (void)dealloc {
    _session = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadCustomView];
    
    //判断权限
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (granted) {
                [self loadScanView];
                [self startRunning];
            } else {
                NSString *title = @"请在iPhone的”设置-隐私-相机“选项中，允许App访问你的相机";
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil];
                [alertView show];
            }
            
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    NSString *codeStr = @"";
    switch (_scanType) {
        case WQCodeScannerTypeAll: codeStr = @"二维码/条码"; break;
        case WQCodeScannerTypeQRCode: codeStr = @"二维码"; break;
        case WQCodeScannerTypeBarcode: codeStr = @"条码"; break;
        default: break;
    }
    
    //title
    if (self.titleStr && self.titleStr.length > 0) {
        self.titleLabel.text = self.titleStr;
    } else {
        self.titleLabel.text = codeStr;
    }
    
    //tip
    if (self.tipStr && self.tipStr.length > 0) {
        self.tipLabel.text = self.tipStr;
    } else {
        self.tipLabel.text= [NSString stringWithFormat:@"将%@放入框内，即可自动扫描", codeStr];
    }

    [self startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:self.originStatusBarStyle animated:YES];
    
    [self stopRunning];
    
    [super viewWillDisappear:animated];
}

- (void)loadScanView {
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [self.session addInput:input];
    [self.session addOutput:output];
    //设置扫码支持的编码格式
    switch (self.scanType) {
        case WQCodeScannerTypeAll:
            output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,
                                         AVMetadataObjectTypeEAN13Code,
                                         AVMetadataObjectTypeEAN8Code,
                                         AVMetadataObjectTypeUPCECode,
                                         AVMetadataObjectTypeCode39Code,
                                         AVMetadataObjectTypeCode39Mod43Code,
                                         AVMetadataObjectTypeCode93Code,
                                         AVMetadataObjectTypeCode128Code,
                                         AVMetadataObjectTypePDF417Code];
            break;
            
        case WQCodeScannerTypeQRCode:
            output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode];
            break;
            
        case WQCodeScannerTypeBarcode:
            output.metadataObjectTypes=@[AVMetadataObjectTypeEAN13Code,
                                         AVMetadataObjectTypeEAN8Code,
                                         AVMetadataObjectTypeUPCECode,
                                         AVMetadataObjectTypeCode39Code,
                                         AVMetadataObjectTypeCode39Mod43Code,
                                         AVMetadataObjectTypeCode93Code,
                                         AVMetadataObjectTypeCode128Code,
                                         AVMetadataObjectTypePDF417Code];
            break;

        default:
            break;
    }
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
}

- (void)loadCustomView {
    self.view.backgroundColor = [UIColor blackColor];
    
    CGRect rc = [[UIScreen mainScreen] bounds];
    //rc.size.height -= 50;
    _width = rc.size.width * 0.1;
    //height = rc.size.height * 0.2;
    _height = (rc.size.height - (rc.size.width - _width * 2))/2;
    
    CGFloat alpha = 0.5;
    
    //最上部view
    UIView* upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rc.size.width, _height)];
    upView.alpha = alpha;
    upView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:upView];
    
    //左侧的view
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, _height, _width, rc.size.height - _height * 2)];
    leftView.alpha = alpha;
    leftView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:leftView];
    
    //中间扫描区域
    UIImageView *scanCropView=[[UIImageView alloc] initWithFrame:CGRectMake(_width, _height, rc.size.width - _width - _width, rc.size.height - _height - _height)];
    scanCropView.image=[UIImage imageNamed:@"login_scan_code_border"];
    scanCropView. backgroundColor =[ UIColor clearColor ];
    [ self.view addSubview :scanCropView];
    
    //右侧的view
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(rc.size.width - _width, _height, _width, rc.size.height - _height * 2)];
    rightView.alpha = alpha;
    rightView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:rightView];
    
    //底部view
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, rc.size.height - _height, rc.size.width, _height)];
    downView.alpha = alpha;
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];
    
    //用于说明的label
    self.tipLabel= [[UILabel alloc] init];
    self.tipLabel.backgroundColor = [UIColor clearColor];
    self.tipLabel.frame=CGRectMake(_width, rc.size.height - _height, rc.size.width - _width * 2, 40);
    self.tipLabel.numberOfLines=0;
    self.tipLabel.textColor=[UIColor whiteColor];
    self.tipLabel.textAlignment = NSTextAlignmentCenter;
    self.tipLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:self.tipLabel];
    
    //画中间的基准线
    self.lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake (_width, _height, rc.size.width - 2 * _width, 5)];
    self.lineImageView.image = [UIImage imageNamed:@"wq_code_scanner_line"];
    [self.view addSubview:self.lineImageView];
    
    
    //标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, rc.size.width - 50 - 50, 44)];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];
    
    //返回
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 44, 44)];
    [backButton setImage:[UIImage imageNamed:@"wq_code_scanner_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(pressBackButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
}

- (void)startRunning {
    if (self.session) {
        _isReading = YES;
        
        [self.session startRunning];
        
        _timer=[NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(moveUpAndDownLine) userInfo:nil repeats: YES];
    }
}

- (void)stopRunning {
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil ;
    }
    
    [self.session stopRunning];
}

- (void)pressBackButton {
    UINavigationController *nvc = self.navigationController;
    if (nvc) {
        if (nvc.viewControllers.count == 1) {
            [nvc dismissViewControllerAnimated:YES completion:nil];
        } else {
            [nvc popViewControllerAnimated:NO];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


//二维码的横线移动
- (void)moveUpAndDownLine {
    CGFloat Y = self.lineImageView.frame.origin.y;
    if (_height + self.lineImageView.frame.size.width - 5 == Y) {
        [UIView beginAnimations: @"asa" context:nil];
        [UIView setAnimationDuration:1.5];
        CGRect frame = self.lineImageView.frame;
        frame.origin.y = _height;
        self.lineImageView.frame = frame;
        [UIView commitAnimations];
    } else if (_height == Y){
        [UIView beginAnimations: @"asa" context:nil];
        [UIView setAnimationDuration:1.5];
        CGRect frame = self.lineImageView.frame;
        frame.origin.y = _height + self.lineImageView.frame.size.width - 5;
        self.lineImageView.frame = frame;
        [UIView commitAnimations];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (!_isReading) {
        return;
    }
    if (metadataObjects.count > 0) {
        _isReading = NO;
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *result = metadataObject.stringValue;
        
        if (self.resultBlock) {
            self.resultBlock(result?:@"");
        }
        
        [self pressBackButton];
    }
}

@end
