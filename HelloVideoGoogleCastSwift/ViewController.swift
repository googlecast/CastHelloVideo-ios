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
import GoogleCast

@objc(HGCViewController) // No need of this
class ViewController: UIViewController, GCKDeviceScannerListener, GCKDeviceManagerDelegate,
                                        GCKMediaControlChannelDelegate, UIActionSheetDelegate {
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
    }()!
  private lazy var btnImageselected:UIImage = {
    return UIImage(named: "icon-cast-connected.png")!
    }()!
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
    deviceScanner?.addListener(self)
    deviceScanner?.startScan()
    deviceScanner?.passiveScan = true
  }

    func chooseDevice(sender:AnyObject) {
        deviceScanner?.passiveScan = false
        let friendlyName = "Casting to \(selectedDevice!.friendlyName)"
        if (selectedDevice == nil) {
            
            let alert = UIAlertController(title: "Connect to Device", message: "Connect the nearby devices", preferredStyle: UIAlertControllerStyle.actionSheet)
            
            for device in (deviceScanner?.devices)!
            {
                
                alert.addAction(UIAlertAction(title: friendlyName, style: UIAlertActionStyle.default, handler: { (alert:UIAlertAction!) in
                    print("foo")
                }))
            }
            
            
            alert.addAction(UIAlertAction(title: cancleTitle, style: UIAlertActionStyle.cancel, handler: nil))
            alert.show(self, sender: (Any).self)
        }
        else
        {
            updateStatus()
            let friendlyName = "Casting to \(selectedDevice!.friendlyName)"
            
            
            let alert = UIAlertController(title: friendlyName, message: "disConnect the nearby devices", preferredStyle: UIAlertControllerStyle.actionSheet)
            
            
            if let info = mediaInformation {
                alert.addAction(UIAlertAction(title: (info.metadata.object(forKey: kGCKMetadataKeyTitle) as! String ), style: UIAlertActionStyle.default, handler: nil))
            }
            
            alert.addAction(UIAlertAction(title: disconnectTitle, style: UIAlertActionStyle.cancel, handler: nil))
            alert.show(self, sender: (Any).self)
        }
    }
    // MARK:- Added updateStatus
    func updateStatus()
    {
        if deviceManager?.connectionState == GCKConnectionState.connected
            && mediaControlChannel?.mediaStatus != nil {
            mediaInformation = mediaControlChannel?.mediaStatus.mediaInformation
        }
    }
    func connectToDevice()
    {
        if (selectedDevice == nil)
        {
            return
        }
        let identifier = Bundle.main.bundleIdentifier
        deviceManager = GCKDeviceManager(device: selectedDevice, clientPackageName: identifier)
        deviceManager!.delegate = self
        deviceManager!.connect()
    }
    
    func deviceDisconnected()
    {
        selectedDevice = nil
        deviceManager = nil
    }
    
    func updateButtonStates()
    {
        if ((deviceScanner?.devices)!.count > 0)
        {
            // Showing The Cast Button
            
            navigationItem.rightBarButtonItems = [castButton!]
            if (deviceManager != nil && deviceManager?.connectionState == GCKConnectionState.connected) {
                
                //  Showing The Cast Button In Active Mode
                castButton!.tintColor = UIColor.blue
            } else {
                // Showing The Cast Button In InActive/Disabled Mode
                castButton!.tintColor = UIColor.gray
            }
        } else
        {
            // Not Showing Cast Button
            navigationItem.rightBarButtonItems = []
        }
    }
  //Cast video
  @IBAction func castVideo(sender:AnyObject) {
    if (deviceManager?.connectionState != GCKConnectionState.connected) {
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Not Connected",
                                          message: "Please connect the Availlable Device",
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertView.init(title: "Not Connected",
                                         message: "Connet to the Cast Device", delegate: nil, cancelButtonTitle: "OK",
                                         otherButtonTitles: "")
            alert.show()
        }
        return
    }
    
    // MARK:- Starting Metadata
    
    // Define Media Metadata.
    let metadata = GCKMediaMetadata()
    metadata?.setString("Enter The Title", forKey: kGCKMetadataKeyTitle)
    metadata?.setString("Enter the string .",
                        forKey:kGCKMetadataKeySubtitle)
    
    let url = NSURL(string:"Enter Url of the image file ")
    metadata?.addImage(GCKImage(url: url! as URL, width: 480, height: 360))
    
    // MARK:- Starting load Media
    
    // Define Media Information.
    let mediaInformation = GCKMediaInformation(
        contentID:
        "Enter URL of thr video file",
        streamType: GCKMediaStreamType.none,
        contentType: "video/mp4",
        metadata: metadata,
        streamDuration: 0,
        mediaTracks: [],
        textTrackStyle: nil,
        customData: nil
    )
    // Cast the media
    mediaControlChannel!.loadMedia(mediaInformation, autoplay: true)
  }

    func showError(error: NSError) {
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: "Error",
                                          message: error.description,
                                          preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertView.init(title: "Error", message: error.description, delegate: nil,
                                         cancelButtonTitle: "OK", otherButtonTitles: "")
            alert.show()
        }
    }
    private func deviceDidComeOnline(device: GCKDevice!) {
        print("Device found: \(device.friendlyName)")
        updateButtonStates()
    }
    
    private func deviceDidGoOffline(device: GCKDevice!) {
        print("Device offline: \(device.friendlyName)")
        updateButtonStates()
    }
    // MARK: UIActionSheetDelegate
    
    private func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        deviceScanner?.passiveScan = true
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return
        } else if (selectedDevice == nil) {
            if (buttonIndex < (deviceScanner?.devices.count)!) {
                selectedDevice = deviceScanner?.devices[buttonIndex] as? GCKDevice
                print("Selected device: \(selectedDevice!.friendlyName)")
                connectToDevice()
            }
        } else if (actionSheet.buttonTitle(at: buttonIndex) == disconnectTitle) {
            // Disconnect button.
            deviceManager!.leaveApplication()
            deviceManager!.disconnect()
            deviceDisconnected()
            updateButtonStates()
        }
    }
    
    
    
    // MARK :- Media Control Channel
    
    // MARK: GCKDeviceManagerDelegate
    
    
    
    func deviceManagerDidConnect(_ deviceManager: GCKDeviceManager!) {
        print("Connected.")
        
        updateButtonStates()
        deviceManager.launchApplication(receiverAPPID)
    }
    
    
    
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
    
    
    private func deviceManager(deviceManager: GCKDeviceManager!,
                               didFailToConnectToApplicationWithError error: Error!) {
        print("Received notification that device failed to connect to application.")
        
        showError(error: error! as NSError)
        deviceDisconnected()
        updateButtonStates()
    }
    
    private func deviceManager(deviceManager: GCKDeviceManager!,
                               didFailToConnectWithError error: NSError!) {
        print("Received notification that device failed to connect.")
        
        showError(error: error!)
        deviceDisconnected()
        updateButtonStates()
    }
    
    private func deviceManager(deviceManager: GCKDeviceManager!,
                               didDisconnectWithError error: Error!) {
        print("Received notification that device disconnected.")
        
        if (error != nil) {
            showError(error: error! as NSError)
        }
        
        deviceDisconnected()
        updateButtonStates()
    }
    
    private func deviceManager(deviceManager: GCKDeviceManager!,
                               didReceiveApplicationMetadata metadata: GCKApplicationMetadata!) {
        applicationMetaData = metadata
    }
}


