// Copyright 2019 Google LLC. All Rights Reserved.
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

#import "ViewController.h"
#import <GoogleCast/GoogleCast.h>

@interface ViewController () <GCKSessionManagerListener,
                              GCKRemoteMediaClientListener,
                              GCKRequestDelegate> {
}

@property(nonatomic, weak) IBOutlet UIButton *castVideoButton;
@property(nonatomic, weak) IBOutlet UILabel *castInstructionLabel;

@property(nonatomic, strong) GCKUICastButton *castButton;
@property(nonatomic, strong) GCKMediaInformation *mediaInformation;
@property(nonatomic, strong) GCKSessionManager *sessionManager;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Initially hide the cast button until a session is started.
  [self showLoadVideoButton:NO];

  self.sessionManager = [GCKCastContext sharedInstance].sessionManager;
  [self.sessionManager addListener:self];

  // Add cast button.
  self.castButton = [[GCKUICastButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];

  // Used to overwrite the theme in AppDelegate.
  self.castButton.tintColor = [UIColor darkGrayColor];

  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithCustomView:self.castButton];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(castDeviceDidChange:)
                                               name:kGCKCastStateDidChangeNotification
                                             object:[GCKCastContext sharedInstance]];
}

- (void)castDeviceDidChange:(NSNotification *)notification {
  if ([GCKCastContext sharedInstance].castState != GCKCastStateNoDevicesAvailable) {
    // Display the instructions for how to use Google Cast on the first app use.
    [[GCKCastContext sharedInstance]
        presentCastInstructionsViewControllerOnceWithCastButton:self.castButton];
  }
}

#pragma mark - Cast Actions

- (void)playVideoRemotely {
  [[GCKCastContext sharedInstance] presentDefaultExpandedMediaControls];

  // Define media metadata.
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
  [metadata setString:@"Big Buck Bunny (2008)" forKey:kGCKMetadataKeyTitle];
  [metadata setString:@"Big Buck Bunny tells the story of a giant rabbit with a "
                       "heart bigger than himself. When one sunny day three rodents rudely harass him, "
                       "something snaps... and the rabbit ain't no bunny anymore! In the "
                       "typical cartoon tradition he prepares the nasty rodents a comical revenge."
               forKey:kGCKMetadataKeySubtitle];
  [metadata addImage:[[GCKImage alloc]
                         initWithURL:
                             [[NSURL alloc]
                                 initWithString:@"https://commondatastorage.googleapis.com/"
                                                 "gtv-videos-bucket/sample/images/BigBuckBunny.jpg"]
                               width:480
                              height:360]];

  // Define information about the media item.
  GCKMediaInformationBuilder *mediaInfoBuilder = [[GCKMediaInformationBuilder alloc]
                                                  initWithContentURL:[NSURL URLWithString:@"https://commondatastorage.googleapis.com/"
                                                  "gtv-videos-bucket/sample/BigBuckBunny.mp4"]];
  mediaInfoBuilder.streamType = GCKMediaStreamTypeNone;
  mediaInfoBuilder.contentType = @"video/mp4";
  mediaInfoBuilder.metadata = metadata;
  self.mediaInformation = [mediaInfoBuilder build];

  GCKMediaLoadRequestDataBuilder *mediaLoadRequestDataBuilder = [[GCKMediaLoadRequestDataBuilder alloc] init];
  mediaLoadRequestDataBuilder.mediaInformation = self.mediaInformation;

  // Send a load request to the remote media client.
  GCKRequest *request = [self.sessionManager.currentSession.remoteMediaClient
                                  loadMediaWithLoadRequestData:[mediaLoadRequestDataBuilder build]];
  if (request != nil) {
    request.delegate = self;
  }
}

- (IBAction)loadVideoWithSender:(id)sender {
  NSLog(@"Load Video");

  if (!self.sessionManager.currentSession) {
    NSLog(@"Cast device not connected");
    return;
  }

  [self playVideoRemotely];
}

- (void)showLoadVideoButton:(BOOL)yn {
  self.castVideoButton.hidden = !yn;
  // Instructions should always be the opposite visibility of the video button.
  self.castInstructionLabel.hidden = !self.castVideoButton.hidden;
}

#pragma mark - GCKSessionManagerListener

- (void)sessionManager:(GCKSessionManager *)sessionManager didStartSession:(GCKSession *)session {
  NSLog(@"sessionManager didStartSession %@", session);

  // Add GCKRemoteMediaClientListener.
  if (session.remoteMediaClient) {
    [session.remoteMediaClient addListener:self];
  }

  [self showLoadVideoButton:YES];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didResumeSession:(GCKSession *)session {
  NSLog(@"sessionManager didResumeSession %@", session);

  // Add GCKRemoteMediaClientListener.
  if (session.remoteMediaClient) {
    [session.remoteMediaClient addListener:self];
  }

  [self showLoadVideoButton:YES];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
         didEndSession:(GCKSession *)session
             withError:(NSError *)error {
  NSLog(@"sessionManager didEndSession %@", session);

  // Remove GCKRemoteMediaClientListener.
  if (session.remoteMediaClient) {
    [session.remoteMediaClient removeListener:self];
  }

  [self showLoadVideoButton:NO];

  if (error) {
    [self showError:error];
  }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
    didFailToStartSessionWithError:(NSError *)error {
  NSLog(@"sessionManager didFailToStartSessionWithError %@", error);

  [self showLoadVideoButton:NO];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
    didFailToResumeSession:(GCKSession *)session
                 withError:(NSError *)error {
  NSLog(@"sessionManager didFailToResumeSession: %@ error: %@", session, error);

  // Remove GCKRemoteMediaClientListener.
  if (session.remoteMediaClient) {
    [session.remoteMediaClient removeListener:self];
  }

  [self showLoadVideoButton:NO];
}

#pragma mark - GCKRemoteMediaClientListener

- (void)remoteMediaClient:(GCKRemoteMediaClient *)player
     didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus {
  self.mediaInformation = mediaStatus.mediaInformation;
}

#pragma mark - GCKRequestDelegate

- (void)requestDidComplete:(GCKRequest *)request {
  NSLog(@"request %ld completed", request.requestID);
}

- (void)request:(GCKRequest *)request didFailWithError:(GCKError *)error {
  NSLog(@"request %ld didFailWithError %@", request.requestID, error);
}

- (void)request:(GCKRequest *)request didAbortWithReason:(GCKRequestAbortReason)abortReason {
  NSLog(@"request %ld didAbortWithReason %ld", request.requestID, (long)abortReason);
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
