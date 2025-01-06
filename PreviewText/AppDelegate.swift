/*
 *  AppDelegate.swift
 *  PreviewText
 *
 *  Created by Tony Smith on 9/08/2023.
 *  Copyright ©2024 Tony Smith. All rights reserved.
 */


import Cocoa
import CoreServices
import WebKit



@main
final class AppDelegate: NSObject,
                         NSApplicationDelegate,
                         URLSessionDelegate,
                         URLSessionDataDelegate,
                         WKNavigationDelegate {

    // MARK:- Class UI Properies
    // Menu Items
    @IBOutlet var helpMenu: NSMenuItem!
    @IBOutlet var helpMenuOnlineHelp: NSMenuItem!
    @IBOutlet var helpMenuAppStoreRating: NSMenuItem!
    @IBOutlet var helpMenuReportBug: NSMenuItem!
    @IBOutlet var helpMenuWhatsNew: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewMarkdown: NSMenuItem!
    @IBOutlet var helpMenuOthersPreviewCode: NSMenuItem!
    @IBOutlet var helpMenuOtherspreviewYaml: NSMenuItem!
    @IBOutlet var helpMenuOtherspreviewJson: NSMenuItem!
    
    @IBOutlet var mainMenuSettings: NSMenuItem!
    
    // Panel Items
    @IBOutlet var versionLabel: NSTextField!
    // FROM 1.0.5
    @IBOutlet var copyrightLabel: NSTextField!

    // Windows
    @IBOutlet var window: NSWindow!

    // Report Sheet
    @IBOutlet weak var reportWindow: NSWindow!
    @IBOutlet weak var feedbackText: NSTextField!
    @IBOutlet weak var connectionProgress: NSProgressIndicator!

    // Preferences Sheet
    @IBOutlet weak var preferencesWindow: NSWindow!
    @IBOutlet weak var fontSizeSlider: NSSlider!
    @IBOutlet weak var fontSizeLabel: NSTextField!
    @IBOutlet weak var codeFontPopup: NSPopUpButton!
    @IBOutlet weak var codeStylePopup: NSPopUpButton!
    @IBOutlet weak var inkColourWell: NSColorWell!
    @IBOutlet weak var paperColourWell: NSColorWell!
    @IBOutlet weak var useLightCheckbox: NSButton!
    @IBOutlet weak var foregroundLabel: NSTextField!
    @IBOutlet weak var backgroundLabel: NSTextField!
    @IBOutlet weak var lineSpacingPopup: NSPopUpButton!
    @IBOutlet weak var noteLabel: NSTextField!
    @IBOutlet weak var previewView: NSTextView!
    @IBOutlet weak var previewScrollView: NSScrollView!
    // FROM 1.0.5
    @IBOutlet weak var minimumSizePopup: NSPopUpButton!

    // What's New Sheet
    @IBOutlet weak var whatsNewWindow: NSWindow!
    @IBOutlet weak var whatsNewWebView: WKWebView!


    // MARK:- Private Properies
    internal var whatsNewNav: WKNavigation?     = nil
    private  var feedbackTask: URLSessionTask?  = nil
    private  var boolStyle: Int                 = BUFFOON_CONSTANTS.BOOL_STYLE.FULL
    private  var bodyFontSize: CGFloat          = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
    private  var bodyFontName: String           = BUFFOON_CONSTANTS.BODY_FONT_NAME
    private  var inkColourHex: String           = BUFFOON_CONSTANTS.INK_COLOUR_HEX
    private  var paperColourHex: String         = BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
    private  var lineSpacing: CGFloat           = BUFFOON_CONSTANTS.BASE_LINE_SPACING
    private  var doShowLightBackground: Bool    = false
    internal var isMontereyPlus: Bool           = false
    private  var isLightMode: Bool              = true
    //private  var havePrefsChanged: Bool         = false
    internal var bodyFonts: [PMFont] = []
    // FROM 1.0.5
    private var minimumThumbSize: Int           = BUFFOON_CONSTANTS.MIN_THUMB_SIZE

    /*
     Replace the following string with your own team ID. This is used to
     identify the app suite and so share preferences set by the main app with
     the previewer and thumbnailer extensions.
     */
    private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME


    // MARK: - Class Lifecycle Functions

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Asynchronously get the list of code fonts
        DispatchQueue.init(label: "com.bps.previewtext.async-queue").async {
            self.asyncGetFonts()
        }

        // Set application group-level defaults
        registerPreferences()
        recordSystemState()
        
        // Add the app's version number to the UI
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.stringValue = "Version \(version) (\(build))"

        // Disable the Help menu Spotlight features
        let dummyHelpMenu: NSMenu = NSMenu.init(title: "Dummy")
        let theApp = NSApplication.shared
        theApp.helpMenu = dummyHelpMenu
        
        // Watch for macOS UI mode changes
        DistributedNotificationCenter.default.addObserver(self,
                                                          selector: #selector(interfaceModeChanged),
                                                          name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
                                                          object: nil)

        // FRON 1.0.5
        // Auto-set the date
        let year = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year
        self.copyrightLabel.stringValue = "Copyright © \(year!) Tony Smith. All rights reserved."

        // Centre the main window and display
        self.window.center()
        self.window.makeKeyAndOrderFront(self)

        // Show the 'What's New' panel if we need to
        // NOTE Has to take place at the end of the function
        doShowWhatsNew(self)
    }


    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {

        // When the main window closed, shut down the app
        return true
    }


    // MARK:- Action Functions

    /**
     Called from **File > Close** and the various Quit controls.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doClose(_ sender: Any) {
        
        // Reset the QL thumbnail cache... just in case it helps
        _ = runProcess(app: "/usr/bin/qlmanage", with: ["-r", "cache"])
        
        // Check for open panels
        if self.preferencesWindow.isVisible {
            if checkPrefs() {
                let alert: NSAlert = showAlert("You have unsaved settings",
                                               "Do you wish to cancel and save them, or quit the app anyway?",
                                               false)
                alert.addButton(withTitle: "Quit")
                alert.addButton(withTitle: "Cancel")
                alert.beginSheetModal(for: self.preferencesWindow) { (response: NSApplication.ModalResponse) in
                    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                        // The user clicked 'Quit'
                        self.preferencesWindow.close()
                        self.window.close()
                    }
                }
                
                return
            }
            
            self.preferencesWindow.close()
        }
        
        if self.whatsNewWindow.isVisible {
            self.whatsNewWindow.close()
        }
        
        if self.reportWindow.isVisible {
            if self.feedbackText.stringValue.count > 0 {
                let alert: NSAlert = showAlert("You have unsent feedback",
                                               "Do you wish to cancel and send it, or quit the app anyway?",
                                               false)
                alert.addButton(withTitle: "Quit")
                alert.addButton(withTitle: "Cancel")
                alert.beginSheetModal(for: self.reportWindow) { (response: NSApplication.ModalResponse) in
                    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                        // The user clicked 'Quit'
                        self.reportWindow.close()
                        self.window.close()
                    }
                }
                
                return
            }
            
            self.reportWindow.close()
        }
        
        // Close the window... which will trigger an app closure
        self.window.close()
    }
    
    
    /**
     Called from various **Help** items to open various websites.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doShowSites(sender: Any) {
        
        // Open the websites for contributors, help and suc
        let item: NSMenuItem = sender as! NSMenuItem
        var path: String = BUFFOON_CONSTANTS.URL_MAIN
        
        // Depending on the menu selected, set the load path
        if item == self.helpMenuAppStoreRating {
            path = BUFFOON_CONSTANTS.APP_STORE + "?action=write-review"
        } else if item == self.helpMenuOnlineHelp {
            path += "#how-to-use-previewtext"
        } else if item == self.helpMenuOthersPreviewMarkdown {
            path = BUFFOON_CONSTANTS.APP_URLS.PM
        } else if item == self.helpMenuOthersPreviewCode {
            path = BUFFOON_CONSTANTS.APP_URLS.PC
        } else if item == self.helpMenuOtherspreviewYaml {
            path = BUFFOON_CONSTANTS.APP_URLS.PY
        } else if item == self.helpMenuOtherspreviewJson {
            path = BUFFOON_CONSTANTS.APP_URLS.PJ
        }
        
        // Open the selected website
        NSWorkspace.shared.open(URL.init(string:path)!)
    }

    
    /**
     Open the System Preferences app at the Extensions pane.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doOpenSysPrefs(sender: Any) {

        // Open the System Preferences app at the Extensions pane
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    }


    // MARK: - Report Functions

    /**
     Display a window in which the user can submit feedback, or report a bug.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doShowReportWindow(sender: Any?) {

        // Reset the UI
        hidePanelGenerators()
        self.connectionProgress.stopAnimation(self)
        self.feedbackText.stringValue = ""

        // Present the window
        self.window.beginSheet(self.reportWindow,
                               completionHandler: nil)
    }


    /**
     User has clicked the Report window's **Cancel** button, so just close the sheet.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doCancelReportWindow(sender: Any) {

        // User has clicked the Report window's 'Cancel' button,
        // so just close the sheet

        self.connectionProgress.stopAnimation(self)
        self.window.endSheet(self.reportWindow)
        showPanelGenerators()
    }

    
    /**
     User has clicked the Report window's **Send** button.

     Get the message (if there is one) from the text field and submit it.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction @objc private func doSendFeedback(sender: Any) {

        // User has clicked the Report window's 'Send' button,
        // so get the message (if there is one) from the text field and submit it
        
        let feedback: String = self.feedbackText.stringValue

        if feedback.count > 0 {
            // Start the connection indicator if it's not already visible
            self.connectionProgress.startAnimation(self)

            /*
             Add your own `func sendFeedback(_ feedback: String) -> URLSessionTask?` function
             */
            
            self.feedbackTask = sendFeedback(feedback)
            
            if self.feedbackTask != nil {
                // We have a valid URL Session Task, so start it to send
                self.feedbackTask!.resume()
                return
            } else {
                // Report the error
                sendFeedbackError()
            }
        }
        
        // No feedback, so close the sheet
        self.window.endSheet(self.reportWindow)
        showPanelGenerators()
        
        // NOTE sheet closes asynchronously unless there was no feedback to send,
        //      or an error occured with setting up the feedback session
    }
    

    // MARK: - Preferences Functions

    /**
     Initialise and display the **Preferences** sheet.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowPreferences(sender: Any) {
        
        // Disable menus we don't want active while the panel is open
        hidePanelGenerators()
        
        // Reset the changes flag
        //self.havePrefsChanged = false
        
        // Prep the preview view
        self.previewView.isSelectable = false
        self.previewScrollView.wantsLayer = true
        self.previewScrollView.layer?.borderWidth = 2.0
        self.previewScrollView.layer?.cornerRadius = 8.0
        
        // Check for the OS mode
        self.isLightMode = isMacInLightMode()

#if DEBUG
        self.foregroundLabel.stringValue = self.isLightMode ? "LIGHT" : "DARK"
        self.backgroundLabel.stringValue = self.useLightCheckbox.state == .on ? "ON" : "OFF"
#endif
        
        // The suite name is the app group name, set in each the entitlements file of
        // the host app and of each extension
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            self.bodyFontSize = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE))
            self.doShowLightBackground = defaults.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            self.bodyFontName = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME) ?? BUFFOON_CONSTANTS.BODY_FONT_NAME
            self.inkColourHex = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR) ?? BUFFOON_CONSTANTS.INK_COLOUR_HEX
            self.paperColourHex = defaults.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR) ?? BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
            self.lineSpacing = CGFloat(defaults.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING))
            // FROM 1.0.5
            self.minimumThumbSize = defaults.integer(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MIN_SIZE)
        }

        // Get the menu item index from the stored value
        // NOTE The index is that of the list of available fonts (see 'Common.swift') so
        //      we need to convert this to an equivalent menu index because the menu also
        //      contains a separator and two title items
        let index: Int = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.lastIndex(of: self.bodyFontSize) ?? 3
        self.fontSizeSlider.floatValue = Float(index)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        
        // Set the checkboxes
        self.useLightCheckbox.state = self.doShowLightBackground ? .on : .off
        self.useLightCheckbox.isEnabled = !self.isLightMode
        
        // Set the colour panel's initial view
        NSColorPanel.setPickerMode(.RGB)
        if self.isLightMode || self.doShowLightBackground {
            // Light mode, so ink = foreground, paper = background
            self.inkColourWell.color = NSColor.hexToColour(self.inkColourHex)
            self.paperColourWell.color = NSColor.hexToColour(self.paperColourHex)
        } else {
            // Dark mode, so ink = background, paper = foreground
            self.inkColourWell.color = NSColor.hexToColour(self.paperColourHex)
            self.paperColourWell.color = NSColor.hexToColour(self.inkColourHex)
        }
        
        // Set the colour shift warning's state
        self.noteLabel.alphaValue = self.isLightMode ? 0.25 : 1.0
        
        // Set the font name popup
        // List the current system's monospace fonts
        self.codeFontPopup.removeAllItems()
        for i: Int in 0..<self.bodyFonts.count {
            let font: PMFont = self.bodyFonts[i]
            self.codeFontPopup.addItem(withTitle: font.displayName)
        }
        
        // Set the font style
        self.codeStylePopup.isEnabled = false
        selectFontByPostScriptName(self.bodyFontName)
        
        // Set the line spacing selector
        switch(round(self.lineSpacing * 100) / 100.0) {
            case 1.15:
                self.lineSpacingPopup.selectItem(at: 1)
            case 1.5:
                self.lineSpacingPopup.selectItem(at: 2)
            case 2.0:
                self.lineSpacingPopup.selectItem(at: 3)
            default:
                self.lineSpacingPopup.selectItem(at: 0)
        }
        
        // Draw a preview preview
        doRenderPreview()

        // FROM 1.0.5
        let itemIndex: Int = BUFFOON_CONSTANTS.THUMB_SIZES.firstIndex(of: self.minimumThumbSize) ?? 3
        self.minimumSizePopup.selectItem(at: itemIndex)

        // Display the sheet
        self.window.beginSheet(self.preferencesWindow, completionHandler: nil)
    }

    
    /**
        Close the **Preferences** sheet and save any settings that have changed.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doSavePreferences(sender: Any) {

        // Save any changed preferences
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            
            // Check for and record a use light background change
            let useLightColours: Bool = self.useLightCheckbox.state == .on
            if self.doShowLightBackground != useLightColours {
                defaults.setValue(useLightColours,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            }
            
            if self.isLightMode || useLightColours {
                // In Light Mode, or in Dark Mode and the user wants a light preview
                
                // Check for and record an ink colour change
                var newColour: String = self.inkColourWell.color.hexString
                if newColour != self.inkColourHex {
                    self.inkColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR)
                }
                
                // Check for and record a paper colour change
                newColour = self.paperColourWell.color.hexString
                if newColour != self.paperColourHex {
                    self.paperColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR)
                }
            } else {
                // In Dark Mode, and the user wants a dark preview
                var newColour: String = self.inkColourWell.color.hexString
                if newColour != self.paperColourHex {
                    self.paperColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR)
                }
                
                newColour = self.paperColourWell.color.hexString
                if newColour != self.inkColourHex {
                    self.inkColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR)
                }
            }
            
            // Check for and record a font and style change
            if let fontName: String = getPostScriptName() {
                if fontName != self.bodyFontName {
                    self.bodyFontName = fontName
                    defaults.setValue(fontName,
                                      forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME)
                }
            }
            
            // Check for and record a font size change
            let newValue: CGFloat = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
            if newValue != self.bodyFontSize {
                defaults.setValue(newValue,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            }
            
            // Save the selected line spacing
            let lineIndex: Int = self.lineSpacingPopup.indexOfSelectedItem
            var lineSpacing: CGFloat = 1.0
            switch(lineIndex) {
                case 1:
                    lineSpacing = 1.15
                case 2:
                    lineSpacing = 1.5
                case 3:
                    lineSpacing = 2.0
                default:
                    lineSpacing = 1.0
            }
            
            if (self.lineSpacing != lineSpacing) {
                self.lineSpacing = lineSpacing
                defaults.setValue(lineSpacing, forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            }

            // FROM 1.0.5
            let minSize: Int = BUFFOON_CONSTANTS.THUMB_SIZES[self.minimumSizePopup.indexOfSelectedItem]
            if minSize != self.minimumThumbSize {
                defaults.setValue(self.minimumThumbSize, forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MIN_SIZE)
            }
            
            // Sync any changes
            defaults.synchronize()
        }
        
        // Close the sheet and tidy up
        closePrefsWindow()
    }
    
    
    /**
        Close the **Preferences** sheet without saving.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doClosePreferences(sender: Any) {
        
        if checkPrefs() {
            let alert: NSAlert = showAlert("You have made changes",
                                           "Do you wish to go back and save them, or ignore them? ",
                                           false)
            alert.addButton(withTitle: "Go Back")
            alert.addButton(withTitle: "Ignore Changes")
            alert.beginSheetModal(for: self.preferencesWindow) { (response: NSApplication.ModalResponse) in
                if response != NSApplication.ModalResponse.alertFirstButtonReturn {
                    // The user clicked 'Cancel'
                    self.closePrefsWindow()
                }
            }
        } else {
            closePrefsWindow()
        }
    }
    
    
    /**
        Tidy up and close the **Preferences** sheet.
     */
    private func closePrefsWindow() {
        
        // Close the colour selection panel(s) if they're open
        closeColourWells()
        
        // Shut the window
        self.window.endSheet(self.preferencesWindow)
        
        // Restore menus
        showPanelGenerators()
    }
    

    /**
        Close any open colour wells.
     */
    private func closeColourWells() {
        
        if self.inkColourWell.isActive {
            NSColorPanel.shared.close()
            self.inkColourWell.deactivate()
        }

        if self.paperColourWell.isActive {
            NSColorPanel.shared.close()
            self.paperColourWell.deactivate()
        }
    }
    
    
    /**
        Check the preference values when the sheet is cancelled in case any
        have been changed by the user.
     
        - Returns: `true` if the settings have been changed.
     */
    private func checkPrefs() -> Bool {
        
        var haveChanged: Bool = false
        
        // Check for a use light background change
        let state: Bool = self.useLightCheckbox.state == .on
        haveChanged = (self.doShowLightBackground != state)
        
        // Check for and record an indent change
        if !haveChanged {
            let lineIndex: Int = self.lineSpacingPopup.indexOfSelectedItem
            var lineSpacing: CGFloat = 1.0
            switch(lineIndex) {
                case 1:
                    lineSpacing = 1.15
                case 2:
                    lineSpacing = 1.5
                case 3:
                    lineSpacing = 2.0
                default:
                    lineSpacing = 1.0
            }
        
            haveChanged = (round(self.lineSpacing * 100) / 100.0 != lineSpacing)
        }
        
        // Check for and record a font and style change
        if let fontName: String = getPostScriptName() {
            if !haveChanged {
                haveChanged = (fontName != self.bodyFontName)
            }
        }
        
        // Check for and record a font size change
        if !haveChanged {
            haveChanged = (self.bodyFontSize != BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)])
        }
        
        // Check for thumbnail minimum size change
        if !haveChanged {
            haveChanged = (self.minimumThumbSize != BUFFOON_CONSTANTS.THUMB_SIZES[self.minimumSizePopup.indexOfSelectedItem])
        }
        
        // Check for ink/paper colour changes
        // NOTE `state` is `true` if the user wants a light preview in dark mode
        if !haveChanged && (self.isLightMode || (!self.isLightMode && state)) {
            // In Light Mode, or in Dark Mode and the user wants a light preview
            var newColour: String = self.inkColourWell.color.hexString
            if newColour != self.inkColourHex {
                haveChanged = true
            }
            
            newColour = self.paperColourWell.color.hexString
            if newColour != self.paperColourHex {
                haveChanged = true
            }
        } else {
            // In Dark Mode, and the user wants a dark preview
            var newColour: String = self.inkColourWell.color.hexString
            if newColour != self.paperColourHex {
                haveChanged = true
            }
            
            newColour = self.paperColourWell.color.hexString
            if newColour != self.inkColourHex {
                haveChanged = true
            }
        }
        
        return haveChanged
    }
    

    /**
        When the font size slider is moved and released, this function updates the font size readout.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doMoveSlider(sender: Any) {
        
        let index: Int = Int(self.fontSizeSlider.floatValue)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        //self.havePrefsChanged = true
        
        // Update the preview
        doRenderPreview()
    }


    /**
     Called when the user selects a font from the list.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateFonts(sender: Any) {
        
        //self.havePrefsChanged = true
        
        // Update the font's styles list
        setStylePopup()
        
        // Update the preview
        doRenderPreview()
    }

    
    /**
     Called when the user selects a style from the list.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateStyle(sender: Any) {
        
        //self.havePrefsChanged = true
        
        // Update the preview
        doRenderPreview()
    }


    /**
     Called when the user selects a thumbnail size from the list.
     FROM 1.0.5

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateMinSize(sender: Any) {
        
        /*
        if self.minimumThumbSize != BUFFOON_CONSTANTS.THUMB_SIZES[self.minimumSizePopup.indexOfSelectedItem] {
            self.minimumThumbSize = BUFFOON_CONSTANTS.THUMB_SIZES[self.minimumSizePopup.indexOfSelectedItem]
            self.havePrefsChanged = true
        }
        */
    }

    
    /**
        Respond to a click on the **use light background** checkbox.

        This is only possible in Dark Mode (control disabled in Light Mode).

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction @objc func doSwitchColours(_ sender: Any) {
        
        // Swap the colours
        let tempColour: NSColor = self.inkColourWell.color
        self.inkColourWell.color = self.paperColourWell.color
        self.paperColourWell.color = tempColour
        
        // Update the preview
        doRenderPreview()
        
        // Set the warning note's state (greyed out when it's not relevant)
        self.noteLabel.alphaValue = self.useLightCheckbox.state == .on ? 0.25 : 1.0
    }
    
    
    /**
        Called when either NSColorWell's value is changed.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction @objc func doChangeColours(_ sender: Any) {
        
        //self.havePrefsChanged = true
        
        // Update the preview
        doRenderPreview()
    }
    
    
    /**
        Render a preview sample based on the current NSColorWell colours
        and mode settings.
     */
    private func doRenderPreview() {

        // Load in the code sample we'll preview the themes with
        guard let loadedCode = loadBundleFile(BUFFOON_CONSTANTS.FILE_CODE_SAMPLE) else { return }
        
        let common: Common = Common.init(false)
        common.paperColour = self.paperColourWell.color.hexString
        common.inkColour = self.inkColourWell.color.hexString
        common.fontSize = BUFFOON_CONSTANTS.PREVIEW_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
        
        var lineSpacing: CGFloat = 1.0
        switch(self.lineSpacingPopup.indexOfSelectedItem) {
            case 1:
                lineSpacing = 1.15
            case 2:
                lineSpacing = 1.5
            case 3:
                lineSpacing = 2.0
            default:
                lineSpacing = 1.0
        }
    
        
        common.lineSpacing = lineSpacing
        common.setProperties(false, getPostScriptName() ?? BUFFOON_CONSTANTS.BODY_FONT_NAME)
        
        // Render the sample text and drop it into the view
        let pas: NSAttributedString = common.getAttributedString(loadedCode)
        self.previewView.backgroundColor = NSColor.hexToColour(common.paperColour)

        if let renderTextStorage: NSTextStorage = self.previewView.textStorage {
            renderTextStorage.beginEditing()
            renderTextStorage.setAttributedString(pas)
            renderTextStorage.endEditing()
            self.previewView.display()
        }
    }

    
    /**
     Load a known text file from the app bundle.
     
     - Parameters:
        - file: The name of the text file without its extension.
     
     - Returns: The contents of the loaded file
     */
    private func loadBundleFile(_ fileName: String, _ type: String = "txt") -> String? {
        
        // Load the required resource and return its contents
        guard let filePath: String = Bundle.main.path(forResource: fileName, ofType: type)
        else {
            // TODO Post error
            return nil
        }
        
        do {
            let fileContents: String = try String.init(contentsOf: URL.init(fileURLWithPath: filePath))
            return fileContents
        } catch {
            // TODO Post error
        }
        
        return nil
    }
    
    
    /**
        Generic IBAction for any Prefs control to register it has been used.
     
        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func checkboxClicked(sender: Any) {
        
        //self.havePrefsChanged = true
        
        let tempColour: NSColor = self.inkColourWell.color
        self.inkColourWell.color = self.paperColourWell.color
        self.paperColourWell.color = tempColour
        
        // FROM 1.0.1 -- Render preview on changes
        self.doRenderPreview()
        
#if DEBUG
            self.foregroundLabel.stringValue = self.isLightMode ? "LIGHT" : "DARK"
            self.backgroundLabel.stringValue = self.useLightCheckbox.state == .on ? "ON" : "OFF"
#endif
    }


    // MARK: - What's New Sheet Functions

    /**
        Show the **What's New** sheet.

        If we're on a new, non-patch version, of the user has explicitly
        asked to see it with a menu click See if we're coming from a menu click
        (`sender != self`) or directly in code from *appDidFinishLoading()*
        (`sender == self`)

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doShowWhatsNew(_ sender: Any) {

        // See if we're coming from a menu click (sender != self) or
        // directly in code from 'appDidFinishLoading()' (sender == self)
        var doShowSheet: Bool = type(of: self) != type(of: sender)
        
        if !doShowSheet {
            // We are coming from the 'appDidFinishLoading()' so check
            // if we need to show the sheet by the checking the prefs
            if let defaults = UserDefaults(suiteName: self.appSuiteName) {
                // Get the version-specific preference key
                let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
                doShowSheet = defaults.bool(forKey: key)
            }
        }
      
        // Configure and show the sheet
        if doShowSheet {
            // Hide manus we don't want used
            hidePanelGenerators()
            
            // First, get the folder path
            let htmlFolderPath = Bundle.main.resourcePath! + "/new"
            
            // Set up the WKWebBiew: no elasticity, horizontal scroller
            self.whatsNewWebView.enclosingScrollView?.hasHorizontalScroller = false
            self.whatsNewWebView.enclosingScrollView?.horizontalScrollElasticity = .none
            self.whatsNewWebView.enclosingScrollView?.verticalScrollElasticity = .none
            
            // Just in case, make sure we can load the file
            if FileManager.default.fileExists(atPath: htmlFolderPath) {
                let htmlFileURL = URL.init(fileURLWithPath: htmlFolderPath + "/new.html")
                let htmlFolderURL = URL.init(fileURLWithPath: htmlFolderPath)
                self.whatsNewNav = self.whatsNewWebView.loadFileURL(htmlFileURL, allowingReadAccessTo: htmlFolderURL)
            }
        }
    }


    /**
        Close the **What's New** sheet.

        Make sure we clear the preference flag for this minor version, so that
        the sheet is not displayed next time the app is run (unless the version changes)

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doCloseWhatsNew(_ sender: Any) {

        // Close the sheet
        self.window.endSheet(self.whatsNewWindow)
        
        // Scroll the web view back to the top
        self.whatsNewWebView.evaluateJavaScript("window.scrollTo(0,0)", completionHandler: nil)

        // Set this version's preference
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
            defaults.setValue(false, forKey: key)

            #if DEBUG
            print("\(key) reset back to true")
            defaults.setValue(true, forKey: key)
            #endif

            defaults.synchronize()
        }
        
        // Restore menus
        showPanelGenerators()
    }


    // MARK: - Misc Functions

    /**
     Called by the app at launch to register its initial defaults.
     */
    private func registerPreferences() {

        // Check if each preference value exists -- set if it doesn't
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            
            // Preview body font size, stored as a CGFloat
            // Default: 16.0
            let bodyFontSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            if bodyFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE)
            }

            // Thumbnail view base font size, stored as a CGFloat, not currently used
            // Default: 28.0
            let thumbFontSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_FONT_SIZE)
            if thumbFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE),
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_FONT_SIZE)
            }
            
            // Colour of JSON keys in the preview, stored as in integer array index
            // Default: #CA0D0E
            var colourDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR)
            if colourDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.INK_COLOUR_HEX,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR)
            }
            
            // Colour of JSON markers in the preview, stored as in integer array index
            // Default: #0096FF
            colourDefault = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR)
            if colourDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.PAPER_COLOUR_HEX,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR)
            }
            
            // Use light background even in dark mode, stored as a bool
            // Default: false
            let useLightDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            if useLightDefault == nil {
                defaults.setValue(false,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)
            }

            // Show the What's New sheet
            // Default: true
            // This is a version-specific preference suffixed with, eg, '-2-3'. Once created
            // this will persist, but with each new major and/or minor version, we make a
            // new preference that will be read by 'doShowWhatsNew()' to see if the sheet
            // should be shown this run
            let key: String = BUFFOON_CONSTANTS.PREFS_IDS.MAIN_WHATS_NEW + getVersion()
            let showNewDefault: Any? = defaults.object(forKey: key)
            if showNewDefault == nil {
                defaults.setValue(true, forKey: key)
            }
            
            // Store the preview line spacing value
            let lineSpacingDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            if lineSpacingDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.BASE_LINE_SPACING,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING)
            }
            
            // FROM 1.0.5
            // Store the miniumum thumbnail render size
            let minThumbSizeDefault: Any? = defaults.object(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MIN_SIZE)
            if minThumbSizeDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.MIN_THUMB_SIZE,
                                  forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MIN_SIZE)
            }

            // Sync any additions
            defaults.synchronize()
        }

    }


    /**
     Handler for macOS UI mode change notifications
     */
    @objc private func interfaceModeChanged() {
        
        // FROM 1.0.6
        // macOS 14 appears to switch values from earlier versions.
        // See note 2 below
        if #available(macOS 14, *) {
            self.isLightMode = isMacInLightMode()
        } else {
            self.isLightMode = !isMacInLightMode()
        }
        
        if self.preferencesWindow.isVisible {
#if DEBUG
            self.foregroundLabel.stringValue = self.isLightMode ? "LIGHT" : "DARK"
            self.backgroundLabel.stringValue = self.useLightCheckbox.state == .on ? "ON" : "OFF"
#endif
            
            // Prefs window is up, so switch the use light background checkbox
            // on or off according to whether the current mode is light
            // NOTE 1 For light mode, this checkbox is irrelevant, so the
            //        checkbox should be disabled
            // NOTE 2 Appearance it this point seems to reflect the mode
            //        we're coming FROM, not what it has changed TO
            self.useLightCheckbox.isEnabled = !self.isLightMode
            
            if self.useLightCheckbox.state == .off {
                // Swap the NSColorWell values around as we're
                // changing mode -- the checkbox freezes the mode
                let tempColour: NSColor = self.inkColourWell.color
                self.inkColourWell.color = self.paperColourWell.color
                self.paperColourWell.color = tempColour
            }
            
            // Update the preview
            doRenderPreview()
            
            // Set the warning note's state (greyed out when it's not relevant)
            self.noteLabel.alphaValue = self.isLightMode ? 0.25 : 1.0
        }
    }

}
