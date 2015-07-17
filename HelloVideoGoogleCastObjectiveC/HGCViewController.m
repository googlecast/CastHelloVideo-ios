// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "HGCViewController.h"


static NSString * kReceiverAppID;

@interface HGCViewController () {

  UIImage *_btnImage;
  UIImage *_btnImageSelected;
}

@property GCKMediaControlChannel *mediaControlChannel;
@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property(nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property(nonatomic, strong) UIButton *chromecastButton;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;
@property(nonatomic, readonly) GCKMediaInformation *mediaInformation;

@end

@implementation HGCViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  //You can add your own app id here that you get by registering with the Google Cast SDK
  //Developer Console https://cast.google.com/publish
  kReceiverAppID=kGCKMediaDefaultReceiverApplicationID;

  //Create chromecast button
  _btnImage = [UIImage imageNamed:@"icon-cast-identified.png"];
  _btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];

  _chromecastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [_chromecastButton addTarget:self
                        action:@selector(chooseDevice:)
              forControlEvents:UIControlEventTouchDown];
  _chromecastButton.frame = CGRectMake(0, 0, _btnImage.size.width, _btnImage.size.height);
  [_chromecastButton setImage:nil forState:UIControlStateNormal];
  _chromecastButton.hidden = YES;

  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithCustomView:_chromecastButton];

  //Establish filter criteria
  GCKFilterCriteria *filterCriteria = [GCKFilterCriteria
                                       criteriaForAvailableApplicationWithID:kReceiverAppID];
  //Initialize device scanner
  self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];

  [self.deviceScanner addListener:self];
  [self.deviceScanner startScan];

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)chooseDevice:(id)sender {
  //Choose device
  if (self.selectedDevice == nil) {
    //Choose device
    UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];

    for (GCKDevice *device in self.deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;

    //show device selection
    [sheet showInView:_chromecastButton];
  } else {
    // Gather stats from device.
    [self updateStatsFromDevice];

    NSString *mediaTitle = [self.mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];

    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = self.selectedDevice.friendlyName;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }

    //Offer disconnect option
    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);

    [sheet showInView:_chromecastButton];
  }
}

- (void)updateStatsFromDevice {

  if (self.mediaControlChannel && self.isDeviceConnected) {
    _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
  }
}

- (BOOL)isDeviceConnected {
  return self.deviceManager.applicationConnectionState == GCKConnectionStateConnected;
}

- (void)connectToDevice {
  if (self.selectedDevice == nil)
    return;

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice
                             clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];

}

- (void)deviceDisconnected {
  self.mediaControlChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
}

- (void)updateButtonStates {
  if (self.deviceScanner.devices.count == 0) {
    //Hide the cast button
    _chromecastButton.hidden = YES;
  } else {
    //Show cast button
    [_chromecastButton setImage:_btnImage forState:UIControlStateNormal];
    _chromecastButton.hidden = NO;

    if (self.deviceManager && self.isDeviceConnected) {
      //Show cast button in enabled state
      [_chromecastButton setTintColor:[UIColor blueColor]];
    } else {
      //Show cast button in disabled state
      [_chromecastButton setTintColor:[UIColor grayColor]];

    }
  }

}

//Cast video
- (IBAction)castVideo:(id)sender {
  NSLog(@"Cast Video");

  //Show alert if not connected
  if (!self.deviceManager || !self.isDeviceConnected) {
    UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Not Connected", nil)
                                   message:NSLocalizedString(@"Please connect to Cast device", nil)
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                         otherButtonTitles:nil];
    [alert show];
    return;
  }

  //Define Media metadata
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];

  [metadata setString:@"Big Buck Bunny (2008)" forKey:kGCKMetadataKeyTitle];

  [metadata setString:@"Big Buck Bunny tells the story of a giant rabbit with a heart bigger than "
                       "himself. When one sunny day three rodents rudely harass him, something "
                       "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon "
                       "tradition he prepares the nasty rodents a comical revenge."
               forKey:kGCKMetadataKeySubtitle];

  [metadata addImage:[[GCKImage alloc]
      initWithURL:[[NSURL alloc] initWithString:@"http://commondatastorage.googleapis.com/"
                                                 "gtv-videos-bucket/sample/images/BigBuckBunny.jpg"]
            width:480
           height:360]];

  //define Media information
  GCKMediaInformation *mediaInformation =
      [[GCKMediaInformation alloc] initWithContentID:
              @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                                          streamType:GCKMediaStreamTypeNone
                                         contentType:@"video/mp4"
                                            metadata:metadata
                                      streamDuration:0
                                          customData:nil];

  //cast video
  [_mediaControlChannel loadMedia:mediaInformation autoplay:TRUE playPosition:0];

}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
  NSLog(@"device found!! %@", device.friendlyName);
  [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  [self updateButtonStates];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (self.selectedDevice == nil) {
    if (buttonIndex < self.deviceScanner.devices.count) {
      self.selectedDevice = self.deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", self.selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    if (buttonIndex == 1) {  //Disconnect button
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      // New way of doing things: We're not going to stop the applicaton. We're just going
      // to leave it.
      [self.deviceManager leaveApplication];
      // If you want to force application to stop, uncomment below
      //[self.deviceManager stopApplicationWithSessionID:self.applicationMetadata.sessionID];
      [self.deviceManager disconnect];

      [self deviceDisconnected];
      [self updateButtonStates];
    } else if (buttonIndex == 0) {
      // Join the existing session.

    }
  }
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected!!");

  [self updateButtonStates];
  [self.deviceManager launchApplication:kReceiverAppID];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {

  NSLog(@"application has launched");
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.mediaControlChannel requestStatus];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectToApplicationWithError:(NSError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error {
  NSLog(@"Received notification that device disconnected");

  if (error != nil) {
    [self showError:error];
  }

  [self deviceDisconnected];
  [self updateButtonStates];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata {
  self.applicationMetadata = applicationMetadata;
}

#pragma mark - misc
- (void)showError:(NSError *)error {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                  message:NSLocalizedString(error.description, nil)
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

@end
