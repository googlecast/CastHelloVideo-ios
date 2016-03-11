# hello-cast-video-ios

This Hello Video demo application shows how an iOS sender application can cast a Video.  For simplicity this app is not fully compliant with the UX Checklist. 

## Dependencies
* CocoaPods - dependencies are managed via CocoaPods. See http://guides.cocoapods.org/using/getting-started.html for setup instructions.
* Alternatively, you may download the iOS Sender API library directly at: [https://developers.google.com/cast/docs/developers#ios](https://developers.google.com/cast/docs/developers#ios "iOS Sender API library")

## Setup Instructions (With CocoaPods)
* Get a Chromecast device and get it set up for development: https://developers.google.com/cast/docs/developers#Get_started
* Register an application on the Developers Console [http://cast.google.com/publish](http://cast.google.com/publish "Google Cast Developer Console"). The easiest would be to use the Styled Media Receiver option there. You will get an App ID when you finish registering your application.
* Run `pod install` in the CastHelloVideo-ios directory
* Open the .xcworkspace file rather the the xcproject to ensure you have the pod dependencies.
* In HGCViewController.m, replace @"YOUR\_APP\_ID\_HERE" with your app identifier from the Google Cast Developer Console. When you are done, it will look something like: 
  * static NSString *const kReceiverAppID = @"1234ABCD";

## Setup Instructions (Without CocoaPods)
* Get a Chromecast device and get it set up for development: https://developers.google.com/cast/docs/developers#Get_started
* Register an application on the Developers Console [http://cast.google.com/publish](http://cast.google.com/publish "Google Cast Developer Console"). The easiest would be to use the Styled Media Receiver option there. You will get an App ID when you finish registering your application.
* Setup the project dependencies in xCode
* For each target you want to build, under "Build Settings", add "-ObjC" to "Other Linker Flags"
* For each target you want to build, under "Build Phases", add the following ent
ries to "Link Binary With Libraries":
  * libc++.dylib
  * Accelerate.framework
  * AudioToolbox.framework
  * AVFoundation.framework
  * CoreBluetooth.framework
  * MediaPlayer.framework
* In HGCViewController.m, replace @"YOUR\_APP\_ID\_HERE" with your app identifier from the Google Cast Developer Console. When you are done, it will look something like: 
  * static NSString *const kReceiverAppID = @"1234ABCD";

## Documentation
Google Cast iOS Sender Overview:  [https://developers.google.com/cast/docs/ios_sender](https://developers.google.com/cast/docs/ios_sender "Google Cast iOS Sender Overview")

## References and How to report bugs
* Cast APIs: [https://developers.google.com/cast/](https://developers.google.com/cast/ "Google Cast Documentation")
* Google Cast Design Checklist [http://developers.google.com/cast/docs/design_checklist](http://developers.google.com/cast/docs/design_checklist "Google Cast Design Checklist")
* If you find any issues, please open a bug here on GitHub
* Question are answered on [StackOverflow](http://stackoverflow.com/questions/tagged/google-cast)

## How to make contributions?
Please read and follow the steps in the [CONTRIBUTING.md](CONTRIBUTING.md)

## License
See [LICENSE](LICENSE)

## Terms
Your use of this sample is subject to, and by using or downloading the sample files you agree to comply with, the [Google APIs Terms of Service](https://developers.google.com/terms/) and the [Google Cast SDK Additional Developer Terms of Service](https://developers.google.com/cast/docs/terms/).

## Google+
Google Cast Developers Community on Google+ [http://goo.gl/TPLDxj](http://goo.gl/TPLDxj)
