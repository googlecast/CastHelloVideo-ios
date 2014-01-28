# hello-cast-video-ios

This Hello Video demo application shows how an iOS sender application can cast a Video.  For simplicity this app is not fully compliant with the UX Checklist. 

## Dependencies
* iOS Sender API library : can be downloaded here at: [https://developers.google.com/cast/docs/downloads/](https://developers.google.com/cast/docs/downloads/ "iOS Sender API library")

## Setup Instructions
* Setup a Chromecast device
* Regsiter an application on the Developers Console [http://cast.google.com/publish](http://cast.google.com/publish "Google Cast Developer Console"). The easisest would be to use the Styled Media Receiver option there. You will get an App ID when you finsih registering your application.
* Setup the project dependencies in xCode
* In ChromecastDeviceController.m, replace @"[YOUR\_APP\_ID_HERE]" with your app identifier from the Google Cast Developer Console. When you are done, it will look something like: 
  * static NSString *const kReceiverAppID = @"1234ABCD";

## Documentation
Google Cast iOS Sender Overview:  [https://developers.google.com/cast/docs/ios_sender](https://developers.google.com/cast/docs/ios_sender "Google Cast iOS Sender Overview")

## References and How to report bugs
* Cast APIs: [https://developers.google.com/cast/](https://developers.google.com/cast/ "Google Cast Documentation")
* Google Cast Design Checklist [http://developers.google.com/cast/docs/design_checklist](http://developers.google.com/cast/docs/design_checklist "Google Cast Design Checklist")
* If you find any issues, please open a bug here on GitHub

## How to make contributions?
Please read and follow the steps in the [CONTRIBUTING.md](CONTRIBUTING.md)

## License
See [LICENSE](LICENSE)