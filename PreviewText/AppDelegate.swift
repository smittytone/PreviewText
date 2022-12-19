/*
 *  AppDelegate.swift
 *  PreviewText
 *
 *  Created by Tony Smith on 9/08/2022.
 *  Copyright © 2022 Tony Smith. All rights reserved.
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
    private  var appSuiteName: String           = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME
    private  var feedbackPath: String           = MNU_SECRETS.ADDRESS.B
    private  var lineSpacing: CGFloat           = BUFFOON_CONSTANTS.BASE_LINE_SPACING
    private  var doShowLightBackground: Bool    = false
    private  var isMontereyPlus: Bool           = false
    private  var isLightMode: Bool              = true
    private  var havePrefsChanged: Bool         = false
    
    internal var bodyFonts: [PMFont] = []
    

    // MARK:- Class Lifecycle Functions

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
            if self.havePrefsChanged {
                let alert: NSAlert = showAlert("You have unsaved changes",
                                               "Do you wish to cancel and save this, or quit the app anyway?",
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
                                               "Do you wish to cancel and send this, or quit the app anyway?",
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


    // MARK: Report Functions

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
            
            self.feedbackTask = submitFeedback(feedback)
            
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
    

    // MARK: Preferences Functions

    /**
     Initialise and display the **Preferences** sheet.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doShowPreferences(sender: Any) {
        
        hidePanelGenerators()
        self.havePrefsChanged = false
        
        // Prep the preview view
        self.previewView.isSelectable = false
        self.previewScrollView.wantsLayer = true
        self.previewScrollView.layer?.borderWidth = 2.0
        self.previewScrollView.layer?.cornerRadius = 8.0
        
        // Check for the OS mode
        self.isLightMode = isMacInLightMode()
        
        // The suite name is the app group name, set in each the entitlements file of
        // the host app and of each extension
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            self.bodyFontSize = CGFloat(defaults.float(forKey: "com-bps-previewtext-base-font-size"))
            self.doShowLightBackground = defaults.bool(forKey: "com-bps-previewtext-do-use-light")
            self.bodyFontName = defaults.string(forKey: "com-bps-previewtext-base-font-name") ?? BUFFOON_CONSTANTS.BODY_FONT_NAME
            self.inkColourHex = defaults.string(forKey: "com-bps-previewtext-ink-colour-hex") ?? BUFFOON_CONSTANTS.INK_COLOUR_HEX
            self.paperColourHex = defaults.string(forKey: "com-bps-previewtext-paper-colour-hex") ?? BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
            self.lineSpacing = CGFloat(defaults.float(forKey: "com-bps-previewtext-line-spacing"))
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
        self.noteLabel.alphaValue = self.doShowLightBackground ? 0.25 : 1.0
        
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
        
        // Display the sheet
        self.window.beginSheet(self.preferencesWindow, completionHandler: nil)
    }


    /**
        When the font size slider is moved and released, this function updates the font size readout.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doMoveSlider(sender: Any) {
        
        let index: Int = Int(self.fontSizeSlider.floatValue)
        self.fontSizeLabel.stringValue = "\(Int(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[index]))pt"
        self.havePrefsChanged = true
        doRenderPreview()
    }


    /**
     Called when the user selects a font from the list.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateFonts(sender: Any) {
        
        // Update the menu of available styles
        setStylePopup()
        doRenderPreview()
        self.havePrefsChanged = true
    }

    
    /**
     Called when the user selects a style from the list.

     - Parameters:
        - sender: The source of the action.
     */
    @IBAction private func doUpdateStyle(sender: Any) {
        
        // Update the preview
        doRenderPreview()
        self.havePrefsChanged = true
    }
    
    
    /**
        Close the **Preferences** sheet without saving.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doClosePreferences(sender: Any) {

        // Close the colour selection panel(s) if they're open
        doCloseColourWells()
        
        // Shut the window
        self.window.endSheet(self.preferencesWindow)
        
        // Menu handling
        showPanelGenerators()
    }


    /**
        Close the **Preferences** sheet and save any settings that have changed.

        - Parameters:
            - sender: The source of the action.
     */
    @IBAction private func doSavePreferences(sender: Any) {

        // Close the colour selection panel(s) if they're open
        doCloseColourWells()
        
        // Save any changed preferences
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            
            // Check for and record a use light background change
            let state: Bool = self.useLightCheckbox.state == .on
            if self.doShowLightBackground != state {
                defaults.setValue(state,
                                  forKey: "com-bps-previewtext-do-use-light")
            }
            
            if self.isLightMode || (!self.isLightMode && state) {
                // In Light Mode, or in Dark Mode and the user wants a light preview
                
                // Check for and record an ink colour change
                var newColour: String = self.inkColourWell.color.hexString
                if newColour != self.inkColourHex {
                    self.inkColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: "com-bps-previewtext-ink-colour-hex")
                }
                
                // Check for and record a paper colour change
                newColour = self.paperColourWell.color.hexString
                if newColour != self.paperColourHex {
                    self.paperColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: "com-bps-previewtext-paper-colour-hex")
                }
            } else {
                // In Dark Mode, and the user wants a dark preview
                var newColour: String = self.inkColourWell.color.hexString
                if newColour != self.paperColourHex {
                    self.paperColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: "com-bps-previewtext-paper-colour-hex")
                }
                
                newColour = self.paperColourWell.color.hexString
                if newColour != self.inkColourHex {
                    self.inkColourHex = newColour
                    defaults.setValue(newColour,
                                      forKey: "com-bps-previewtext-ink-colour-hex")
                }
            }
            
            // Check for and record a font and style change
            if let fontName: String = getPostScriptName() {
                if fontName != self.bodyFontName {
                    self.bodyFontName = fontName
                    defaults.setValue(fontName,
                                      forKey: "com-bps-previewtext-base-font-name")
                }
            }
            
            // Check for and record a font size change
            let newValue: CGFloat = BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[Int(self.fontSizeSlider.floatValue)]
            if newValue != self.bodyFontSize {
                defaults.setValue(newValue,
                                  forKey: "com-bps-previewtext-base-font-size")
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
                defaults.setValue(lineSpacing, forKey: "com-bps-previewtext-line-spacing")
            }
            
            // Sync any changes
            defaults.synchronize()
        }
        
        // Remove the sheet now we have the data
        self.window.endSheet(self.preferencesWindow)
        
        // Menu handling
        showPanelGenerators()
    }
    

    /**
        Close all the colour wells that are open.
     */
    private func doCloseColourWells() {
        
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
        
        // Just update the preview.
        // This reads the new colours.
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
    
    
    @IBAction private func checkboxClicked(sender: Any) {
        
        self.havePrefsChanged = true
    }
    
    
    // MARK: What's New Sheet Functions

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

        // Menu handling
        hidePanelGenerators()
        
        // See if we're coming from a menu click (sender != self) or
        // directly in code from 'appDidFinishLoading()' (sender == self)
        var doShowSheet: Bool = type(of: self) != type(of: sender)
        
        if !doShowSheet {
            // We are coming from the 'appDidFinishLoading()' so check
            // if we need to show the sheet by the checking the prefs
            if let defaults = UserDefaults(suiteName: self.appSuiteName) {
                // Get the version-specific preference key
                let key: String = "com-bps-previewtext-do-show-whats-new-" + getVersion()
                doShowSheet = defaults.bool(forKey: key)
            }
        }
      
        // Configure and show the sheet: first, get the folder path
        if doShowSheet {
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
            let key: String = "com-bps-previewtext-do-show-whats-new-" + getVersion()
            defaults.setValue(false, forKey: key)

            #if DEBUG
            print("\(key) reset back to true")
            defaults.setValue(true, forKey: key)
            #endif

            defaults.synchronize()
        }
        
        // Menu handling
        showPanelGenerators()
    }


    // MARK: - Misc Functions

    /**
     Called by the app at launch to register its initial defaults.
     */
    private func registerPreferences() {

        // Check if each preference value exists -- set if it doesn't
        if let defaults = UserDefaults(suiteName: self.appSuiteName) {
            
            //defaults.removeObject(forKey: "com-bps-previewtext-ink-colour-hex")
            //defaults.removeObject(forKey: "com-bps-previewtext-paper-colour-hex")
            
            // Preview body font size, stored as a CGFloat
            // Default: 16.0
            let bodyFontSizeDefault: Any? = defaults.object(forKey: "com-bps-previewtext-base-font-size")
            if bodyFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE),
                                  forKey: "com-bps-previewtext-base-font-size")
            }

            // Thumbnail view base font size, stored as a CGFloat, not currently used
            // Default: 28.0
            let thumbFontSizeDefault: Any? = defaults.object(forKey: "com-bps-previewtext-thumb-font-size")
            if thumbFontSizeDefault == nil {
                defaults.setValue(CGFloat(BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE),
                                  forKey: "com-bps-previewtext-thumb-font-size")
            }
            
            // Colour of JSON keys in the preview, stored as in integer array index
            // Default: #CA0D0E
            var colourDefault: Any? = defaults.object(forKey: "com-bps-previewtext-ink-colour-hex")
            if colourDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.INK_COLOUR_HEX,
                                  forKey: "com-bps-previewtext-ink-colour-hex")
            }
            
            // Colour of JSON markers in the preview, stored as in integer array index
            // Default: #0096FF
            colourDefault = defaults.object(forKey: "com-bps-previewtext-paper-colour-hex")
            if colourDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.PAPER_COLOUR_HEX,
                                  forKey: "com-bps-previewtext-paper-colour-hex")
            }
            
            // Use light background even in dark mode, stored as a bool
            // Default: false
            let useLightDefault: Any? = defaults.object(forKey: "com-bps-previewtext-do-use-light")
            if useLightDefault == nil {
                defaults.setValue(false,
                                  forKey: "com-bps-previewtext-do-use-light")
            }

            // Show the What's New sheet
            // Default: true
            // This is a version-specific preference suffixed with, eg, '-2-3'. Once created
            // this will persist, but with each new major and/or minor version, we make a
            // new preference that will be read by 'doShowWhatsNew()' to see if the sheet
            // should be shown this run
            let key: String = "com-bps-previewtext-do-show-whats-new-" + getVersion()
            let showNewDefault: Any? = defaults.object(forKey: key)
            if showNewDefault == nil {
                defaults.setValue(true, forKey: key)
            }
            
            // Store the preview line spacing value
            let lineSpacingDefault: Any? = defaults.object(forKey: "com-bps-previewtext-line-spacing")
            if lineSpacingDefault == nil {
                defaults.setValue(BUFFOON_CONSTANTS.BASE_LINE_SPACING,
                                  forKey: "com-bps-previewtext-line-spacing")
            }
            
            // Sync any additions
            defaults.synchronize()
        }

    }
    

    /**
     Send the feedback string etc.

     - Parameters:
        - feedback: The text of the user's comment.

     - Returns: A URLSessionTask primed to send the comment, or `nil` on error.
     */
    private func submitFeedback(_ feedback: String) -> URLSessionTask? {

        // Send the feedback string etc.

        // First get the data we need to build the user agent string
        let userAgent: String = getUserAgentForFeedback()
        let endPoint: String = MNU_SECRETS.ADDRESS.A

        // Get the date as a string
        let dateString: String = getDateForFeedback()

        // Assemble the message string
        let dataString: String = """
         *FEEDBACK REPORT*
         *Date:* \(dateString)
         *User Agent:* \(userAgent)
         *FEEDBACK:*
         \(feedback)
         """

        // Build the data we will POST:
        let dict: NSMutableDictionary = NSMutableDictionary()
        dict.setObject(dataString,
                        forKey: NSString.init(string: "text"))
        dict.setObject(true, forKey: NSString.init(string: "mrkdwn"))

        // Make and return the HTTPS request for sending
        if let url: URL = URL.init(string: self.feedbackPath + endPoint) {
            var request: URLRequest = URLRequest.init(url: url)
            request.httpMethod = "POST"

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: dict,
                                                              options:JSONSerialization.WritingOptions.init(rawValue: 0))

                request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
                request.addValue("application/json", forHTTPHeaderField: "Content-type")

                let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
                let session: URLSession = URLSession.init(configuration: config,
                                                          delegate: self,
                                                          delegateQueue: OperationQueue.main)
                return session.dataTask(with: request)
            } catch {
                // NOP
            }
        }

        return nil
    }
    
    
    /**
     Get system and state information and record it for use during run.
     */
    private func recordSystemState() {
        
        // First ensure we are running on Mojave or above - Dark Mode is not supported by earlier versons
        let sysVer: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
        self.isMontereyPlus = (sysVer.majorVersion >= 12)
    }
    
    
    /**
     Handler for macOS UI mode change notifications
     */
    @objc private func interfaceModeChanged() {
        
        self.isLightMode = !isMacInLightMode()
        
        if self.preferencesWindow.isVisible {
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
                
                // Update the preview
                doRenderPreview()
            }
            
            // Set the warning note's state (greyed out when it's not relevant)
            self.noteLabel.alphaValue = self.useLightCheckbox.state == .on ? 0.25 : 1.0
        }
    }
    
    
    /**
     Determine whether the host Mac is in light mode.
     
     - Returns: `true` if the Mac is in light mode, otherwise `false`.
     */
    private func isMacInLightMode() -> Bool {
        
        let appearNameString: String = NSApp.effectiveAppearance.name.rawValue
        return (appearNameString == "NSAppearanceNameAqua")
    }

}
