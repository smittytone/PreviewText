# PreviewText 1.0.1

QuickLook preview and icon thumbnailing app extensions for macOS Catalina and beyond.

*PreviewText* provides previews and thumbnails for textual files that have no file extension, or use non-standard extensions, including `.nfo`, `.1st`, `.asc`, `.srt` and `.sub`.

*PreviewText* is [available free of charge from the Mac App Store](https://apps.apple.com/us/app/previewtext/id1660037028).

![PreviewText App Store QR code](qr-code.png)

## Source Code ##

The source code is provided here for inspection and inspiration. The code will not build as is: graphical, other non-code resources and some code components are not included in the source release. To build PreviewText from scratch, you will need to add these files yourself or remove them from your fork.

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview textual documents using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the *Text Previewer* and *Text Thumbnailer* extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview ###

You can alter some of the key elements of the preview by using the **Preferences** panel.

Changing these settings will affect previews immediately, but may not affect thumbnail until you open a folder that has not been previously opened in the current login session.

## Release Notes ##

* 1.0.1 *Unreleased*
    * Fix issue with line-spacing (thanks @aaronkollasch).
    * Correctly preview line-spacing changes. 
* 1.0.0 *23 December 2022*
    * Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2023, Tony Smith.
