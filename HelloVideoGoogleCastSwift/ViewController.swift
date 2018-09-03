// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License")
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
class ViewController: UIViewController, GCKMediaControlChannelDelegate {
    private let kCancelTitle = "Cancel"
    private let kDisconnectTitle = "Disconnect"
    private var applicationMetadata: GCKApplicationMetadata?
    private var selectedDevice: GCKDevice?
    private var deviceManager: GCKDeviceManager?
    private var mediaInformation: GCKMediaInformation?
    private var mediaControlChannel: GCKMediaControlChannel?
    private var deviceScanner: GCKDeviceScanner
    private lazy var btnImage:UIImage = {
    return UIImage(named: "icon-cast-identified.png")!
    }()
    private lazy var btnImageselected:UIImage = {
    return UIImage(named: "icon-cast-connected.png")!
    }()
    private lazy var kReceiverAppID:String = {
    // You can add your own app id here that you get by registering with the
    // Google Cast SDK Developer Console https://cast.google.com/publish
    return kGCKMediaDefaultReceiverApplicationID
    }()
    @IBOutlet var googleCastButton : UIBarButtonItem!

  // Required init.
    required init(coder aDecoder: NSCoder) {
        let filterCriteria = GCKFilterCriteria(forAvailableApplicationWithID:
            kGCKMediaDefaultReceiverApplicationID)
        deviceScanner = GCKDeviceScanner(filterCriteria:filterCriteria)
        super.init(coder: aDecoder)!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initially hide the Cast button.
        navigationItem.rightBarButtonItems = []

        // Initialize device scanner
        deviceScanner.add(self)
        deviceScanner.startScan()
        deviceScanner.passiveScan = true
    }

    @IBAction func chooseDevice(_ sender: Any) {
        deviceScanner.passiveScan = false
        if selectedDevice == nil {
            let sheet = UIActionSheet(title: "Connect to Device",
                                      delegate: self,
                                      cancelButtonTitle: nil,
                                      destructiveButtonTitle: nil)

            for device in deviceScanner.devices {
                if let gckDevice = device as? GCKDevice {
                    sheet.addButton(withTitle: gckDevice.friendlyName)
                }
            }

            // Add the cancel button at the end so that indexes of the titles map to the array index.
            sheet.addButton(withTitle: kCancelTitle)
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1
            sheet.show(in: self.view)
        } else {
            updateStatsFromDevice()
            let friendlyName = "Casting to \(selectedDevice!.friendlyName)"

            let sheet = UIActionSheet(title: friendlyName,
                                      delegate: self,
                                      cancelButtonTitle: nil,
                                      destructiveButtonTitle: nil)
            var buttonIndex = 0

            if let info = mediaInformation {
                sheet.addButton(withTitle: (info.metadata.object(forKey: kGCKMetadataKeyTitle) as! String))
                buttonIndex += 1
            }

            // Offer disconnect option.
            sheet.addButton(withTitle: kDisconnectTitle)
            sheet.addButton(withTitle: kCancelTitle)
            sheet.destructiveButtonIndex = buttonIndex
            buttonIndex += 1
            sheet.cancelButtonIndex = buttonIndex

            sheet.show(in: self.view)
        }
    }

    func updateStatsFromDevice() {
        if deviceManager?.connectionState == GCKConnectionState.connected && mediaControlChannel?.mediaStatus != nil {
            mediaInformation = mediaControlChannel?.mediaStatus.mediaInformation
        }
    }

    func connectToDevice() {
        if selectedDevice == nil {
            return
        }
        let identifier = Bundle.main.bundleIdentifier
        deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
        deviceManager?.delegate = self
        deviceManager?.connect()
  }

    func deviceDisconnected() {
        selectedDevice = nil
        deviceManager = nil
    }

    func updateButtonStates() {
        if deviceScanner.devices.count > 0 {
            // Show the Cast button.
            navigationItem.rightBarButtonItems = [googleCastButton!]
            if deviceManager != nil && deviceManager?.connectionState == .connected {
                // Show the Cast button in the enabled state.
                googleCastButton?.tintColor = UIColor.blue
            } else {
                // Show the Cast button in the disabled state.
                googleCastButton?.tintColor = UIColor.gray
            }
        } else {
            // Don't show Cast button.
            navigationItem.rightBarButtonItems = []
        }
    }
    
    //Cast video
    @IBAction func castVideo(_ sender: Any) {
        print("Cast Video")

        // Show alert if not connected.
        if deviceManager?.connectionState != .connected {
            if #available(iOS 8.0, *) {
                let alert = UIAlertController(title: "Not Connected",
                                              message: "Please connect to Cast device",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertView(title: "Not Connected",
                                        message: "Please connect to Cast device",
                                        delegate: nil,
                                        cancelButtonTitle: "OK",
                                        otherButtonTitles: "")
                alert.show()
            }
            return
        }

        // [START media-metadata]
        // Define Media Metadata.
        let metadata = GCKMediaMetadata()
        metadata?.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
        metadata?.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger " +
            "than himself. When one sunny day three rodents rudely harass him, something " +
            "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
            "tradition he prepares the nasty rodents a comical revenge.",
                            forKey:kGCKMetadataKeySubtitle)

        let url = URL(string:"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")
        metadata?.addImage(GCKImage(url: url, width: 480, height: 360))
        // [END media-metadata]

        // [START load-media]
        // Define Media Information.
        let mediaInformation = GCKMediaInformation(
            contentID:
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            streamType: GCKMediaStreamType.none,
            contentType: "video/mp4",
            metadata: metadata,
            streamDuration: 0,
            mediaTracks: [],
            textTrackStyle: nil,
            customData: nil
        )

        // Cast the media
        mediaControlChannel?.loadMedia(mediaInformation, autoplay: true)
        // [END load-media]
    }

    func showError(error: Error) {
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertView(title: "Error",
                                    message: error.localizedDescription,
                                    delegate: nil,
                                    cancelButtonTitle: "OK",
                                    otherButtonTitles: "")
            alert.show()
        }
    }
}

// MARK: GCKDeviceScannerListener
extension ViewController: GCKDeviceScannerListener {
    func deviceDidComeOnline(_ device: GCKDevice!) {
        print("Device found: \(device.friendlyName)")
        updateButtonStates()
    }

    func deviceDidGoOffline(_ device: GCKDevice!) {
        print("Device went away: \(device.friendlyName)")
        updateButtonStates()
    }
}


// MARK: UIActionSheetDelegate
extension ViewController: UIActionSheetDelegate {
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        deviceScanner.passiveScan = true
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return
        } else if (selectedDevice == nil) {
            if (buttonIndex < deviceScanner.devices.count) {
                selectedDevice = deviceScanner.devices[buttonIndex] as? GCKDevice
                print("Selected device: \(selectedDevice!.friendlyName)")
                connectToDevice()
            }
        } else if (actionSheet.buttonTitle(at: buttonIndex) == kDisconnectTitle) {
            // Disconnect button.
            deviceManager?.leaveApplication()
            deviceManager?.disconnect()
            deviceDisconnected()
            updateButtonStates()
        }
    }
}

// [START media-control-channel]
// MARK: GCKDeviceManagerDelegate
// [START_EXCLUDE silent]
extension ViewController: GCKDeviceManagerDelegate {

    func deviceManagerDidConnect(_ deviceManager: GCKDeviceManager!) {
        print("Connected.")

        updateButtonStates()
        deviceManager.launchApplication(kReceiverAppID)
    }
    // [END_EXCLUDE]
    func deviceManager(_ deviceManager: GCKDeviceManager!,
                       didConnectToCastApplication
        applicationMetadata: GCKApplicationMetadata!,
                       sessionID: String!,
                       launchedApplication: Bool) {
        print("Application has launched.")
        self.mediaControlChannel = GCKMediaControlChannel()
        mediaControlChannel!.delegate = self
        deviceManager.add(mediaControlChannel)
        mediaControlChannel!.requestStatus()
    }
    // [END media-control-channel]

    func deviceManager(_ deviceManager: GCKDeviceManager!, didFailToConnectToApplicationWithError error: Error!) {
        print("Received notification that device failed to connect to application.")

        showError(error: error)
        deviceDisconnected()
        updateButtonStates()
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!, didFailToConnectWithError error: Error!) {
        print("Received notification that device failed to connect.")

        showError(error: error)
        deviceDisconnected()
        updateButtonStates()
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!, didDisconnectWithError error: Error!) {
        print("Received notification that device disconnected.")

        if (error != nil) {
            showError(error: error)
        }

        deviceDisconnected()
        updateButtonStates()
    }

    func deviceManager(_ deviceManager: GCKDeviceManager!, didReceive metadata: GCKApplicationMetadata!) {
        applicationMetadata = metadata
    }
}
