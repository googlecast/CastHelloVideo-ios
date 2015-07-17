// Copyright 2015 Google Inc. All Rights Reserved.
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

import UIKit

@objc(HGCViewController)
class ViewController: UIViewController, GCKDeviceScannerListener, GCKDeviceManagerDelegate,
                                        GCKMediaControlChannelDelegate, UIActionSheetDelegate {
  let kCancelTitle = "Cancel"
  let kDisconnectTitle = "Disconnect"
  var applicationMetadata: GCKApplicationMetadata?
  var selectedDevice: GCKDevice?
  var deviceManager: GCKDeviceManager?
  var mediaInformation: GCKMediaInformation?
  var mediaControlChannel: GCKMediaControlChannel
  var chromecastButton : UIButton
  var deviceScanner: GCKDeviceScanner
  var btnImage : UIImage
  var btnImageSelected : UIImage
  var kReceiverAppID: String {
    //You can add your own app id here that you get by registering with the
    // Google Cast SDK Developer Console https://cast.google.com/publish
    return kGCKMediaDefaultReceiverApplicationID;
  }

  // Required init.
  required init(coder aDecoder: NSCoder) {
    let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID:
        kGCKMediaDefaultReceiverApplicationID)
    deviceScanner = GCKDeviceScanner(filterCriteria:filterCriteria);
    mediaControlChannel = GCKMediaControlChannel()
    btnImage = UIImage(named: "icon-cast-identified.png")!
    btnImageSelected = UIImage(named:"icon-cast-connected.png")!
    chromecastButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view, typically from a nib.
    chromecastButton.addTarget(self, action: "chooseDevice:", forControlEvents: .TouchUpInside)
    chromecastButton.frame = CGRectMake(0, 0, btnImage.size.width, btnImage.size.height)
    chromecastButton.setImage(nil, forState:UIControlState.Normal)
    chromecastButton.hidden = true

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: chromecastButton)

    // Initialize device scanner
    deviceScanner.addListener(self)
    deviceScanner.startScan()
  }

  func chooseDevice(sender:AnyObject) {
    if (selectedDevice == nil) {
      // [START showing-devices]
      var sheet : UIActionSheet = UIActionSheet(title: "Connect to Device",
        delegate: self,
        cancelButtonTitle: nil,
        destructiveButtonTitle: nil)

      for device in deviceScanner.devices  {
        sheet.addButtonWithTitle(device.friendlyName)
      }

      // [START_EXCLUDE silent]
      // Add the cancel button at the end so that indexes of the titles map to the array index.
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
      // [END_EXCLUDE]
      
      sheet.showInView(chromecastButton)
      // [END showing-devices]
    } else {
      updateStatsFromDevice();
      let friendlyName = "Casting to \(selectedDevice!.friendlyName)";

      var sheet : UIActionSheet = UIActionSheet(title: friendlyName, delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: nil);
      var buttonIndex = 0;

      if let info = mediaInformation {
        sheet.addButtonWithTitle(info.metadata.objectForKey(kGCKMetadataKeyTitle) as! String);
        buttonIndex++;
      }

      // Offer disconnect option.
      sheet.addButtonWithTitle(kDisconnectTitle);
      sheet.addButtonWithTitle(kCancelTitle);
      sheet.destructiveButtonIndex = buttonIndex++;
      sheet.cancelButtonIndex = buttonIndex;

      sheet.showInView(chromecastButton);
    }
  }

  func updateStatsFromDevice() {
    if isConnected() && mediaControlChannel.mediaStatus != nil {
      mediaInformation = mediaControlChannel.mediaStatus.mediaInformation
    }
  }

  func isConnected() -> Bool {
    if let manager = deviceManager {
      return manager.connectionState == GCKConnectionState.Connected
    } else {
      return false
    }
  }

  func connectToDevice() {
    if (selectedDevice == nil) {
      return
    }
    // [START device-selection]
    let identifier = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as! String
    deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
    deviceManager!.delegate = self
    deviceManager!.connect()
    // [END device-selection]
  }

  func deviceDisconnected() {
    selectedDevice = nil
    deviceManager = nil
  }

  func updateButtonStates() {
    if (deviceScanner.devices.count == 0) {
      //Hide the cast button
      chromecastButton.hidden = true;
    } else {
      //Show cast button
      chromecastButton.setImage(btnImage, forState: UIControlState.Normal);
      chromecastButton.hidden = false;

      if isConnected() {
        //Show cast button in enabled state
        chromecastButton.tintColor = UIColor.blueColor()
      } else {
        //Show cast button in disabled state
        chromecastButton.tintColor = UIColor.grayColor()
      }
    }
  }


  //Cast video
  @IBAction func castVideo(sender:AnyObject) {
    println("Cast Video");

    // Show alert if not connected.
    if (!isConnected()) {
      let alert = UIAlertController(title: "Not Connected",
        message: "Please connect to Cast device",
        preferredStyle: UIAlertControllerStyle.Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
      self.presentViewController(alert, animated: true, completion: nil);
      return;
    }

    // [START media-metadata]
    // Define Media Metadata.
    let metadata = GCKMediaMetadata();
    metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle);
    metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
        "himself. When one sunny day three rodents rudely harass him, something " +
        "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
        "tradition he prepares the nasty rodents a comical revenge.",
        forKey:kGCKMetadataKeySubtitle);

    let url = NSURL(string:"https://commondatastorage.googleapis.com/gtv-videos-bucket/" +
      "sample/images/BigBuckBunny.jpg");
    metadata.addImage(GCKImage(URL: url, width: 480, height: 360))
    // [END media-metadata]

    // [START load-media]
    // Define Media Information.
    let mediaInformation = GCKMediaInformation(
      contentID: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      streamType: GCKMediaStreamType.None,
      contentType: "video/mp4",
      metadata: metadata,
      streamDuration: 0,
      mediaTracks: [],
      textTrackStyle: nil,
      customData: nil
    );

    // Cast the media
    mediaControlChannel.loadMedia(mediaInformation, autoplay: true);
    // [END load-media]
  }

  func showError(error: NSError) {
    var alert = UIAlertController(title: "Error", message: error.description, preferredStyle: UIAlertControllerStyle.Alert);
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
    self.presentViewController(alert, animated: true, completion: nil)
  }

}

// MARK: GCKDeviceScannerListener
extension ViewController {

  func deviceDidComeOnline(device: GCKDevice!) {
    println("Device found: \(device.friendlyName)");
    updateButtonStates();
  }

  func deviceDidGoOffline(device: GCKDevice!) {
    println("Device went away: \(device.friendlyName)");
    updateButtonStates();
  }

}


// MARK: UIActionSheetDelegate
extension ViewController {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
      return;
    } else if (selectedDevice == nil) {
      if (buttonIndex < deviceScanner.devices.count) {
        selectedDevice = deviceScanner.devices[buttonIndex] as? GCKDevice;
        println("Selected device: \(selectedDevice!.friendlyName)");
        connectToDevice();
      }
    } else if (actionSheet.buttonTitleAtIndex(buttonIndex) == kDisconnectTitle) {
      // Disconnect button.
      deviceManager!.leaveApplication();
      deviceManager!.disconnect();
      deviceDisconnected();
      updateButtonStates();
    }
  }
}


// MARK: GCKDeviceManagerDelegate
extension ViewController {

  func deviceManagerDidConnect(deviceManager: GCKDeviceManager!) {
    println("Connected.");

    updateButtonStates();
    deviceManager.launchApplication(kReceiverAppID);
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didConnectToCastApplication
    applicationMetadata: GCKApplicationMetadata!,
    sessionID: String!,
    launchedApplication: Bool) {
    println("Application has launched.");
    mediaControlChannel.delegate = self;
    deviceManager.addChannel(mediaControlChannel);
    mediaControlChannel.requestStatus();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectToApplicationWithError error: NSError!) {
    println("Received notification that device failed to connect to application.");

    showError(error);
    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didFailToConnectWithError error: NSError!) {
    println("Received notification that device failed to connect.");

    showError(error);
    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didDisconnectWithError error: NSError!) {
    println("Received notification that device disconnected.");

    if (error != nil) {
      showError(error)
    }

    deviceDisconnected();
    updateButtonStates();
  }

  func deviceManager(deviceManager: GCKDeviceManager!,
    didReceiveApplicationMetadata metadata: GCKApplicationMetadata!) {
    applicationMetadata = metadata;
  }
}