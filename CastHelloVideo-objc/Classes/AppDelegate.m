// Copyright 2018 Google LLC. All Rights Reserved.
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

#import "AppDelegate.h"
#import <GoogleCast/GoogleCast.h>

// You can add your own app id here that you get by registering with the Google
// Cast SDK Developer Console https://cast.google.com/publish or use
// kGCKDefaultMediaReceiverApplicationID
#define kReceiverAppID @"4F8B3483"
#define kDebugLoggingEnabled YES

@interface AppDelegate () <GCKLoggerDelegate> {
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Set your receiver application ID.
  GCKDiscoveryCriteria *criteria =
      [[GCKDiscoveryCriteria alloc] initWithApplicationID:kReceiverAppID];
  GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
  options.physicalVolumeButtonsWillControlDeviceVolume = YES;
  [GCKCastContext setSharedInstanceWithOptions:options];

  // Configure widget styling.
  // Theme using UIAppearance.
  [UINavigationBar appearance].barTintColor = [UIColor lightGrayColor];
  NSDictionary *colorAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
  [UINavigationBar appearance].titleTextAttributes = colorAttributes;
  [GCKUICastButton appearance].tintColor = [UIColor grayColor];

  // Theme using GCKUIStyle.
  GCKUIStyle *castStyle = [GCKUIStyle sharedInstance];
  // Set the property of the desired cast widgets.
  castStyle.castViews.deviceControl.buttonTextColor = [UIColor darkGrayColor];
  // Refresh all currently visible views with the assigned styles.
  [castStyle applyStyle];

  // Enable default expanded controller.
  [GCKCastContext sharedInstance].useDefaultExpandedMediaControls = YES;

  // Enable logger.
  [GCKLogger sharedInstance].delegate = self;

  // Set logger filter.
  GCKLoggerFilter *filter = [[GCKLoggerFilter alloc] init];
  filter.minimumLevel = GCKLoggerLevelError;
  [GCKLogger sharedInstance].filter = filter;

  // Wrap main view in the GCKUICastContainerViewController and display the mini
  // controller.
  UIStoryboard *appStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  UINavigationController *navigationController =
      [appStoryboard instantiateViewControllerWithIdentifier:@"MainNavigation"];
  GCKUICastContainerViewController *castContainerVC = [[GCKCastContext sharedInstance]
      createCastContainerControllerForViewController:navigationController];
  castContainerVC.miniMediaControlsItemEnabled = YES;
  // Color the background to match the embedded content
  castContainerVC.view.backgroundColor = [UIColor whiteColor];

  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.rootViewController = castContainerVC;
  [self.window makeKeyAndVisible];

  return YES;
}

#pragma mark - GCKLoggerDelegate

- (void)logMessage:(NSString *)message
           atLevel:(GCKLoggerLevel)level
      fromFunction:(NSString *)function
          location:(NSString *)location {
  if (kDebugLoggingEnabled) {
    NSLog(@"%@: %@ - %@", location, function, message);
  }
}

@end
