//
//  WQCodeScanner.h
//  CodeScanner
//
//  Created by wangyuxiang on 2017/3/27.
//  Copyright © 2017年 wangyuxiang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WQCodeScannerType) {
    WQCodeScannerTypeAll = 0,   //default, scan QRCode and barcode
    WQCodeScannerTypeQRCode,    //scan QRCode only
    WQCodeScannerTypeBarcode,   //scan barcode only
};

@interface WQCodeScanner : UIViewController

@property (nonatomic, assign) WQCodeScannerType scanType;
@property (nonatomic, copy) NSString *titleStr;
@property (nonatomic, copy) NSString *tipStr;

@property (nonatomic, copy) void(^resultBlock)(NSString *value);

@end
