# CodeScanner
QR code and barcode scanner for iOS7 and later

## Preparing Works
Add `Privacy - Camera Usage Description` to Info.plist.

##Usage
```
WQCodeScanner *scanner = [[WQCodeScanner alloc] init];
[self presentViewController:scanner animated:YES completion:nil];
scanner.resultBlock = ^(NSString *value) {
UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:value message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
[alertView show];
};
```
