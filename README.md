# PreviewJson 1.0.1

QuickLook JSON preview and icon thumbnailing app extensions for macOS Catalina and beyond

![PreviewJson App Store QR code](qr-code.jpg)

## Source Code ##

The source code is provided here for inspection and inspiration. The code will not build as is: graphical, other non-code resources and some code components are not included in the source release. To build PreviewJson from scratch, you will need to add these files yourself or remove them from your fork.

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview markdown documents using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the Previewer and Thumbnailer extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview ###

You can alter some of the key elements of the preview by using the **Preferences** panel:

* The colour of object keys.
* The colour of JSON object and array delimiters, if they are displayed.
* Whether to include JSON object and array delimiters in previews.
* Whether to show raw JSON if it cannot be parsed without error.
* The preview’s monospaced font and text size.
* The body text font.
* Whether preview should be display white-on-black even in Dark Mode.

Changing these settings will affect previews immediately, but may not affect thumbnail until you open a folder that has not been previously opened in the current login session.

## Release Notes ##

* 1.0.1 *4 October 2022*
    * Correct some text style discrepancies.
* 1.0.0 *2 October 2022*
    * Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2022, Tony Smith.