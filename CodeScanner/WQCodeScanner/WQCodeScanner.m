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
{
    UIImageView *_lineImageView;
    NSTimer *_timer;
    UILabel *_tipLabel;
    UILabel *_titleLabel;
}

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) BOOL isReading;

@property (nonatomic, assign) UIStatusBarStyle originStatusBarStyle;

@property (nonatomic, strong) UIImageView *_lineImageView;

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
                NSString *appName = ([NSBundle mainBundle].infoDictionary)[@"CFBundleDisplayName"];
                NSString *title = [NSString stringWithFormat:@"请在iPhone的”设置-隐私-相机“选项中，允许%@访问你的相机", appName];
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
        _titleLabel.text = self.titleStr;
    } else {
        _titleLabel.text = codeStr;
    }
    
    //tip
    if (self.tipStr && self.tipStr.length > 0) {
        _tipLabel.text = self.tipStr;
    } else {
        _tipLabel.text= [NSString stringWithFormat:@"将%@放入框内，即可自动扫描", codeStr];
    }

    [self startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
}

- (void)loadCustomView {
    self.view.backgroundColor = [UIColor blackColor];
    
    CGRect rc = [[UIScreen mainScreen] bounds];
    //rc.size.height -= 50;
    width = rc.size.width * 0.1;
    //height = rc.size.height * 0.2;
    height = (rc.size.height - (rc.size.width - width * 2))/2;
    
    //最上部view
    UIView* upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rc.size.width, height)];
    upView.alpha = TINTCOLOR_ALPHA;
    upView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:upView];
    
    //左侧的view
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, height, width, rc.size.height - height * 2)];
    leftView.alpha = TINTCOLOR_ALPHA;
    leftView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:leftView];
    
    //中间扫描区域
    UIImageView *scanCropView=[[ UIImageView alloc ] initWithFrame : CGRectMake (width , height , rc.size.width - width - width, rc.size.height - height - height)];
    scanCropView.image=[UIImage imageNamed:@"login_scan_code_border"];
    scanCropView. backgroundColor =[ UIColor clearColor ];
    [ self.view addSubview :scanCropView];
    
    //右侧的view
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(rc.size.width - width, height, width, rc.size.height - height * 2)];
    rightView.alpha = TINTCOLOR_ALPHA;
    rightView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:rightView];
    
    //底部view
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, rc.size.height - height, rc.size.width, height)];
    downView.alpha = TINTCOLOR_ALPHA;
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];
    
    //用于说明的label
    labIntroudction= [[UILabel alloc] init];
    labIntroudction.backgroundColor = [UIColor clearColor];
    labIntroudction.frame=CGRectMake(width, rc.size.height - height, rc.size.width - width*2, 40);
    labIntroudction.numberOfLines=0;
    labIntroudction.textColor=[UIColor whiteColor];
    labIntroudction.textAlignment = NSTextAlignmentCenter;
    labIntroudction.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:labIntroudction];
    
    //画中间的基准线
    _QrCodeline = [[UIImageView alloc] initWithFrame:CGRectMake (width, height, MAIN_SCREEN_WIDTH - 2 * width, 5)];
    _QrCodeline.image = [UIImage imageNamed:@"login_scan_code_line"];
    [self.view addSubview:_QrCodeline];
    
    
    //标题
    titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, STATUS_HEIGHT_IOS7, MAIN_SCREEN_WIDTH-50-50, NaVIGATION_HEIGHT)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    //返回
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, STATUS_HEIGHT_IOS7, 44, 44)];
    [backButton setImage:[UIImage imageNamed:@"cm_credit_detail_back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(pressBackButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
}


//打开解码视图
- (void)showDecodeView
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [[[UIApplication sharedApplication].delegate window].rootViewController presentViewController:self animated:YES completion:nil];
    }
    else
    {
        [CLUtil showAlert:GLOBAL_STR(RES_MSG_TIP) msg:GLOBAL_STR(RES_CONFIG_CAMERA)];
    }
}

- (void)startRunning {
    if (self.session) {
        _isReading = YES;
        
        [self.session startRunning];
        
        _timer=[NSTimer scheduledTimerWithTimeInterval: 1.5 target: self selector: @selector (moveUpAndDownLine) userInfo: nil repeats: YES ];
    }
}

- (void)stopRunning {
    if ([_timer isValid] == YES ) {
        [_timer invalidate];
        _timer = nil ;
    }
    
    [self.session stopRunning];
}

- (void)pressBackButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}


//二维码的横线移动
- ( void )moveUpAndDownLine
{
    CGFloat Y= _QrCodeline.frame.origin.y ;
    if (height + _QrCodeline.frame.size.width - 5 == Y){
        [UIView beginAnimations: @"asa" context:nil];
        [UIView setAnimationDuration:1.5];
        _QrCodeline.frame=CGRectMake(width, height, MAIN_SCREEN_WIDTH- 2 * width, 5);
        [UIView commitAnimations];
    } else if (height==Y){
        [UIView beginAnimations: @"asa" context:nil];
        [UIView setAnimationDuration:1.5];
        _QrCodeline.frame=CGRectMake(width, height + _QrCodeline.frame.size.width - 5, MAIN_SCREEN_WIDTH- 2 * width, 5);
        [UIView commitAnimations];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (!_isReading) {
        return;
    }
    if (metadataObjects.count>0) {
        _isReading = NO;
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        NSString *result = metadataObject.stringValue;
        
        if (self.targetDelegate && [self.targetDelegate respondsToSelector:@selector(didFinishReader:)]) {
            [self.targetDelegate didFinishReader:result];
        }
        if (self.targetDelegate && [self.targetDelegate respondsToSelector:@selector(didFinishReader:viewTag:)]) {
            [self.targetDelegate didFinishReader:result viewTag:self.viewTag];
        }
        
        [self pressBackButton];
    }
}


@end
