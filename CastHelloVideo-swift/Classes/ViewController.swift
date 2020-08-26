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

@objc(ViewController)
class ViewController: UIViewController, GCKSessionManagerListener, GCKRemoteMediaClientListener, GCKRequestDelegate {
  @IBOutlet var castVideoButton: UIButton!
  @IBOutlet var castInstructionLabel: UILabel!
  @IBOutlet var credsToggleButton: UIButton!
  @IBOutlet var credsLabel: UILabel!
    
  private var castButton: GCKUICastButton!
  private var mediaInformation: GCKMediaInformation?
  private var sessionManager: GCKSessionManager!
  private let NULL_CREDENTIALS = "N/A"

  override func viewDidLoad() {
    super.viewDidLoad()

    // Initially hide the cast button until a session is started.
    showLoadVideoButton(showButton: false)

    sessionManager = GCKCastContext.sharedInstance().sessionManager
    sessionManager.add(self)

    // Add cast button.
    castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))

    // Used to overwrite the theme in AppDelegate.
    castButton.tintColor = .darkGray
    
    // Initial default value
    self.credsLabel.text = NULL_CREDENTIALS
    setLaunchCreds()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(castDeviceDidChange(notification:)),
                                           name: NSNotification.Name.gckCastStateDidChange,
                                           object: GCKCastContext.sharedInstance())
  }

  @objc func castDeviceDidChange(notification _: Notification) {
    if GCKCastContext.sharedInstance().castState != GCKCastState.noDevicesAvailable {
      // Display the instructions for how to use Google Cast on the first app use.
      GCKCastContext.sharedInstance().presentCastInstructionsViewControllerOnce(with: castButton)
    }
  }

  // MARK: Cast Actions

  func playVideoRemotely() {
    GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()

    // Define media metadata.
    let metadata = GCKMediaMetadata()
    metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
    metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
      "himself. When one sunny day three rodents rudely harass him, something " +
      "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
      "tradition he prepares the nasty rodents a comical revenge.",
                       forKey: kGCKMetadataKeySubtitle)
    metadata.addImage(GCKImage(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                               width: 480,
                               height: 360))

    let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: URL(string:
        "https://storage.googleapis.com/tse-summit.appspot.com/hls/bbb/bbb.m3u8")!)
    mediaInfoBuilder.streamType = GCKMediaStreamType.none
    mediaInfoBuilder.contentType = "video/mp4"
    mediaInfoBuilder.metadata = metadata
    mediaInformation = mediaInfoBuilder.build()

    let mediaLoadRequestDataBuilder = GCKMediaLoadRequestDataBuilder()
    mediaLoadRequestDataBuilder.mediaInformation = mediaInformation
    mediaLoadRequestDataBuilder.credentials = credsLabel.text

    // Send a load request to the remote media client.
    if let request = sessionManager.currentSession?.remoteMediaClient?.loadMedia(with: mediaLoadRequestDataBuilder.build()) {
      request.delegate = self
    }
  }

  // Toggle label text and set those credentials for next session
  @IBAction func setCredentials(_ sender: Any) {
    let credentials = credsLabel.text
    if (credentials == NULL_CREDENTIALS) {
        credsLabel.text = "{\"userId\":\"id123\"}"
    } else {
        credsLabel.text = NULL_CREDENTIALS
    }
    setLaunchCreds()
  }
    
  @IBAction func loadVideo(sender _: AnyObject) {
    print("Load Video")

    if sessionManager.currentSession == nil {
      print("Cast device not connected")
      return
    }

    playVideoRemotely()
  }

  func showLoadVideoButton(showButton: Bool) {
    castVideoButton.isHidden = !showButton
    // Instructions should always be the opposite visibility of the video button.
    castInstructionLabel.isHidden = !castVideoButton.isHidden
  }

  // MARK: GCKSessionManagerListener

  func sessionManager(_: GCKSessionManager,
                      didStart session: GCKSession) {
    print("sessionManager didStartSession: \(session)")

    // Add GCKRemoteMediaClientListener.
    session.remoteMediaClient?.add(self)

    showLoadVideoButton(showButton: true)
  }

  func sessionManager(_: GCKSessionManager,
                      didResumeSession session: GCKSession) {
    print("sessionManager didResumeSession: \(session)")

    // Add GCKRemoteMediaClientListener.
    session.remoteMediaClient?.add(self)

    showLoadVideoButton(showButton: true)
  }

  func sessionManager(_: GCKSessionManager,
                      didEnd session: GCKSession,
                      withError error: Error?) {
    print("sessionManager didEndSession: \(session)")

    // Remove GCKRemoteMediaClientListener.
    session.remoteMediaClient?.remove(self)

    if let error = error {
      showError(error)
    }

    showLoadVideoButton(showButton: false)
  }

  func sessionManager(_: GCKSessionManager,
                      didFailToStart session: GCKSession,
                      withError error: Error) {
    print("sessionManager didFailToStartSessionWithError: \(session) error: \(error)")

    // Remove GCKRemoteMediaClientListener.
    session.remoteMediaClient?.remove(self)

    showLoadVideoButton(showButton: false)
  }

  // MARK: GCKRemoteMediaClientListener

  func remoteMediaClient(_: GCKRemoteMediaClient,
                         didUpdate mediaStatus: GCKMediaStatus?) {
    if let mediaStatus = mediaStatus {
      mediaInformation = mediaStatus.mediaInformation
    }
  }

  // MARK: - GCKRequestDelegate

  func requestDidComplete(_ request: GCKRequest) {
    print("request \(Int(request.requestID)) completed")
  }

  func request(_ request: GCKRequest,
               didFailWithError error: GCKError) {
    print("request \(Int(request.requestID)) didFailWithError \(error)")
  }

  func request(_ request: GCKRequest,
               didAbortWith abortReason: GCKRequestAbortReason) {
    print("request \(Int(request.requestID)) didAbortWith reason \(abortReason)")
  }

  // MARK: Misc

  func showError(_ error: Error) {
    let alertController = UIAlertController(title: "Error",
                                            message: error.localizedDescription,
                                            preferredStyle: UIAlertController.Style.alert)
    let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
    alertController.addAction(action)

    present(alertController, animated: true, completion: nil)
  }
  
  func setLaunchCreds() {
    let creds = credsLabel.text
    GCKCastContext.sharedInstance().setLaunch(GCKCredentialsData(credentials: (creds == NULL_CREDENTIALS) ? nil : creds))
  }
}
