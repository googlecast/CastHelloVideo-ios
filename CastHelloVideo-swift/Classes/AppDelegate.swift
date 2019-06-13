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

import GoogleCast
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GCKLoggerDelegate {
  // You can add your own app id here that you get by registering with the Google Cast SDK
  // Developer Console https://cast.google.com/publish or use kGCKDefaultMediaReceiverApplicationID
  let kReceiverAppID = "C0868879"
  let kDebugLoggingEnabled = true

  var window: UIWindow?

  func applicationDidFinishLaunching(_: UIApplication) {
    // Set your receiver application ID.
    let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    options.physicalVolumeButtonsWillControlDeviceVolume = true
    GCKCastContext.setSharedInstanceWith(options)

    // Configure widget styling.
    // Theme using UIAppearance.
    UINavigationBar.appearance().barTintColor = .lightGray
    let colorAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    UINavigationBar().titleTextAttributes = colorAttributes
    GCKUICastButton.appearance().tintColor = .gray

    // Theme using GCKUIStyle.
    let castStyle = GCKUIStyle.sharedInstance()
    // Set the property of the desired cast widgets.
    castStyle.castViews.deviceControl.buttonTextColor = .darkGray
    // Refresh all currently visible views with the assigned styles.
    castStyle.apply()

    // Enable default expanded controller.
    GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true

    // Enable logger.
    GCKLogger.sharedInstance().delegate = self

    // Set logger filter.
    let filter = GCKLoggerFilter()
    filter.minimumLevel = .error
    GCKLogger.sharedInstance().filter = filter

    // Wrap main view in the GCKUICastContainerViewController and display the mini controller.
    let appStoryboard = UIStoryboard(name: "Main", bundle: nil)
    let navigationController = appStoryboard.instantiateViewController(withIdentifier: "MainNavigation")
    let castContainerVC = GCKCastContext.sharedInstance().createCastContainerController(for: navigationController)
    castContainerVC.miniMediaControlsItemEnabled = true
    // Color the background to match the embedded content
    castContainerVC.view.backgroundColor = .white

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = castContainerVC
    window?.makeKeyAndVisible()
  }

  // MARK: - GCKLoggerDelegate

  func logMessage(_ message: String,
                  at _: GCKLoggerLevel,
                  fromFunction function: String,
                  location: String) {
    if kDebugLoggingEnabled {
      print("\(location): \(function) - \(message)")
    }
  }
}
