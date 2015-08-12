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
#import <GoogleCast/GoogleCast.h>

static NSString * kReceiverAppID;

@interface HGCViewController () <GCKDeviceScannerListener,
                                 GCKDeviceManagerDelegate,
                                 GCKMediaControlChannelDelegate,
                                 UIActionSheetDelegate>{

}

@property GCKMediaControlChannel *mediaControlChannel;
@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *googleCastButton;
@property(nonatomic, strong) GCKDeviceScanner *deviceScanner;
@property(nonatomic, strong) GCKDeviceManager *deviceManager;
@property(nonatomic, strong) GCKMediaInformation *mediaInformation;
@property(nonatomic, strong) UIImage *btnImage;
@property(nonatomic, strong) UIImage *btnImageSelected;

@end

@implementation HGCViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // You can add your own app id here that you get by registering with the Google Cast SDK
  // Developer Console https://cast.google.com/publish
  kReceiverAppID=kGCKMediaDefaultReceiverApplicationID;

  // Create images for Google Cast button.
  self.btnImage = [UIImage imageNamed:@"icon-cast-identified.png"];
  self.btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];

  // Initially hide Cast button.
  self.navigationItem.rightBarButtonItems = @[];

  // Establish filter criteria.
  GCKFilterCriteria *filterCriteria = [GCKFilterCriteria
                                       criteriaForAvailableApplicationWithID:kReceiverAppID];
  // Initialize device scanner.
  self.deviceScanner = [[GCKDeviceScanner alloc] initWithFilterCriteria:filterCriteria];

  [_deviceScanner addListener:self];
  [_deviceScanner startScan];

}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)chooseDevice:(id)sender {
  if (_selectedDevice == nil) {
    // [START showing-devices]
    // Choose device.
    UIActionSheet *sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];

    for (GCKDevice *device in _deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    // [START_EXCLUDE]
    // Further customizations
    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    // [END_EXCLUDE]
    
    // Show device selection.
    [sheet showInView:self.view];
  } else {
    // Gather stats from device.
    [self updateStatsFromDevice];

    NSString *mediaTitle = [_mediaInformation.metadata stringForKey:kGCKMetadataKeyTitle];

    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = _selectedDevice.friendlyName;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }

    // Offer disconnect option.
    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);

    [sheet showInView:self.view];
  }
}

- (void)updateStatsFromDevice {

  if (_mediaControlChannel &&
      _deviceManager.connectionState == GCKConnectionStateConnected) {
    _mediaInformation = _mediaControlChannel.mediaStatus.mediaInformation;
  }
}

- (void)connectToDevice {
  if (_selectedDevice == nil) {
    return;
  }

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:_selectedDevice
                             clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [_deviceManager connect];
}

- (void)deviceDisconnected {
  self.mediaControlChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
}

- (void)updateButtonStates {
  if (_deviceScanner && _deviceScanner.devices.count > 0) {
    // Show the Cast button.
    self.navigationItem.rightBarButtonItems = @[_googleCastButton];
    if (_deviceManager && _deviceManager.connectionState == GCKConnectionStateConnected) {
      // Show the Cast button in the enabled state.
      [_googleCastButton setTintColor:[UIColor blueColor]];
    } else {
      // Show the Cast button in the disabled state.
      [_googleCastButton setTintColor:[UIColor grayColor]];
    }
  } else {
    //Don't show cast button.
    self.navigationItem.rightBarButtonItems = @[];
  }
}

- (IBAction)castVideo:(id)sender {
  NSLog(@"Cast Video");

  // Show alert if not connected.
  if (!_deviceManager
      || _deviceManager.connectionState != GCKConnectionStateConnected) {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Not Connected"
                                        message:@"Please connect to Cast device"
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:nil];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
    return;
  }

  // Define media metadata.
  // [START media-metadata]
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
  // [END media-metadata]

  // Define Media information.
  // [START load-media]
  GCKMediaInformation *mediaInformation =
      [[GCKMediaInformation alloc] initWithContentID:
              @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                                          streamType:GCKMediaStreamTypeNone
                                         contentType:@"video/mp4"
                                            metadata:metadata
                                      streamDuration:0
                                          customData:nil];

  // Cast the video.
  [_mediaControlChannel loadMedia:mediaInformation autoplay:YES playPosition:0];
  // [END load-media]

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
  if (_selectedDevice == nil) {
    if (buttonIndex < _deviceScanner.devices.count) {
      self.selectedDevice = _deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", _selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    if (buttonIndex == 1) {  //Disconnect button
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      // New way of doing things: We're not going to stop the applicaton. We're just going
      // to leave it.
      [_deviceManager leaveApplication];
      [_deviceManager disconnect];

      [self deviceDisconnected];
      [self updateButtonStates];
    } else if (buttonIndex == 0) {
      // Join the existing session.

    }
  }
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected to %@!", _selectedDevice.friendlyName);

  [self updateButtonStates];
  [_deviceManager launchApplication:kReceiverAppID];
}

// [START media-control-channel]
- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {

  NSLog(@"application has launched");
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [_deviceManager addChannel:self.mediaControlChannel];
  // [START_EXCLUDE silent]
  [_mediaControlChannel requestStatus];
  //[END_EXCLUDE silent]
}
// [END media-control-channel]

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
  UIAlertController *alert =
  [UIAlertController alertControllerWithTitle:@"Error"
                                      message:error.description
                               preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK"
                                                   style:UIAlertActionStyleDefault
                                                 handler:nil];
  [alert addAction:action];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
