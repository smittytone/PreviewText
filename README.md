# PreviewText 1.0.8

QuickLook preview and icon thumbnailing app extensions for macOS Catalina and beyond.

*PreviewText* provides previews and thumbnails for textual files that have no file extension, or use non-standard extensions, including `.toml`, `.nfo`, `.1st`, `.srt` and `.sub`.

*PreviewText* is [available free of charge from the Mac App Store](https://apps.apple.com/us/app/previewtext/id1660037028).

![PreviewText App Store QR code](qr-code.png)

## Installation and Usage ##

Just run the host app once to register the extensions &mdash; you can quit the app as soon as it has launched. We recommend logging out of your Mac and back in again at this point. Now you can preview textual documents using QuickLook (select an icon and hit Space), and Finder’s preview pane and **Info** panels.

You can disable and re-enable the *Text Previewer* and *Text Thumbnailer* extensions at any time in **System Preferences > Extensions > Quick Look**.

### Adjusting the Preview ###

You can change some of the key elements of the preview by using the **Preferences** panel.

Changing these settings will affect previews immediately, but may not affect thumbnail until you open a folder that has not been previously opened in the current login session.

## Source Code

This repository contains the primary source code for *PreviewText*. Certain graphical assets, code components and data files are not included. To build *PreviewText* from scratch, you will need to add these files yourself or remove them from your fork.

The files `REPLACE_WITH_YOUR_FUNCTIONS` and `REPLACE_WITH_YOUR_CODES` must be replaced with your own files. The former will contain your `sendFeedback(_ feedback: String) -> URLSessionTask?` function. The latter your Developer Team ID, used as the App Suite identifier prefix.

You will need to generate your own `Assets.xcassets` file containing the app icon, `app_logo.png` and theme screenshots.

You will need to create your own `new` directory containing your own `new.html` file.

## Contributions ##

Contributions are welcome, but pull requestss can only be accepted when they target the `develop` branch. PRs targetting `main` will be rejected.

Contributions will only be accepted if they code they contain is licensed under the terms of [the MIT Licence](#LICENSE.md)

## Release Notes ##

- 1.0.8 *Unreleased*
    - Support <code>.[pub</code> public key files.
    - Improved thumbnail rendering.
- 1.0.7 *1 December 2024*
    - Remove support for `.conf` files — conflict with [PreviewCode](https://smittytone.net/previewcode/index.html) for these files.
    - Correct build target to macOS 10.15 Catalina.
- 1.0.6 *3 September 2024*
    - Support `.conf` and `.config` files.
    - Revert NSTextViews to TextKit 1 (previously bumped to 2 by Xcode).
    - Correct **Preferences** panel preview behaviour in Dark Mode.
    - Improve preference change handling.
    - Fix preview colour changes across modes and mode changes.
- 1.0.5 *29 April 2024*
    - Support `.toml` files.
    - Allow the user to set a minimum size below which thumbnails will not be rendered because they’ll be too small to be of value. Default: 48 pixels.
    - Revise Thumbnailer code with a view to reducing massive memory usage seen by some users, and as-yet-unexplained Thumbnailer crashes.
    - Fix the 'white flash' seen on loading the What's New sheet.
- 1.0.4 *14 August 2023*
    - Non-shipping release: repo/code reorganisation.
- 1.0.3 *12 May 2023*
    - Remove `.asc` — conflict with [PreviewCode](https://smittytone.net/previewcode/index.html) for Asciidoc files.
- 1.0.2 *22 March 2023*
    - Make previewed text selectable.
    - Support `go.mod`, `go.sum` and `go.work` files.
    - Support `.in` and `.out` files.
- 1.0.1 *21 January 2023*
    - Fix issue with line-spacing (thanks @aaronkollasch).
    - Correctly preview line-spacing changes.
- 1.0.0 *23 December 2022*
    - Initial public release.

## Copyright and Credits ##

Primary app code and UI design &copy; 2025, Tony Smith.
