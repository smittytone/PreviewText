/*
 *  PreviewViewController.swift
 *  PreviewText
 *
 *  Created by Tony Smith on 29/08/2023.
 *  Copyright © 2024 Tony Smith. All rights reserved.
 */


import Cocoa
import Quartz


class PreviewViewController: NSViewController,
                             QLPreviewingController {
    
    
    // MARK:- Class UI Properties

    @IBOutlet var renderTextView: NSTextView!
    @IBOutlet var renderTextScrollView: NSScrollView!
    @IBOutlet var previewErrorLabel: NSTextField!
    @IBOutlet var encodingOptions: NSPopUpButton!
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("PreviewViewController")
    }

    
    override func loadView() {
        
        super.loadView()
    }

    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
       /*
        * Main entry point for the macOS preview system
        */
        
        // Prepare the view
        self.previewErrorLabel.stringValue = ""
        self.previewErrorLabel.isHidden = true
        self.renderTextScrollView.isHidden = false
        
        // Get an error message ready for use
        var reportError: NSError? = nil
        
        // Set the base values
        let common: Common = Common.init()
        
        // Load the source file using a co-ordinator as we don't know what thread this function
        // will be executed in when it's called by macOS' QuickLook code
        if FileManager.default.isReadableFile(atPath: url.path) {
            // Only proceed if the file is accessible from here
            do {
                // Get the file contents as a string
                let data: Data = try Data.init(contentsOf: url, options: [.uncached])
                let encoding: String.Encoding = data.stringEncoding ?? .utf8
                
                // FROM 1.0.2
                // Get the UTI to check Go config files
                let sourceFileUTI: String = common.getSourceFileUTI(url.path).lowercased()
                if sourceFileUTI == "com.bps.goconfig" {
                    if !url.lastPathComponent.starts(with: "go.") {
                        reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_GO_CONFIG)
                        showError(reportError!.userInfo[NSLocalizedDescriptionKey] as! String)
                        handler(reportError)
                        return
                    }
                }
                
                if let textString = String.init(data: data, encoding: encoding) {
                    // Get the key string first
                    #if DEBUG
                    var textAttString: NSAttributedString = common.getAttributedString("\(encoding)" + "\n" + textString)
                    #else
                    var textAttString: NSAttributedString = common.getAttributedString(textString)
                    #endif
                    
                    if encoding.rawValue == CFStringConvertEncodingToNSStringEncoding(CFStringConvertWindowsCodepageToEncoding(437)) {
                        if let winFont: NSFont = NSFont.init(name: "More Perfect DOS VFA", size: 18.0) {
                            textAttString = NSAttributedString(string: getEncoding(encoding) + "\n" + textString, attributes: [.font: winFont])
                        }
                    }
                    
                    // Knock back the light background to make the scroll bars visible in dark mode
                    // NOTE If !doShowLightBackground,
                    //              in light mode, the scrollers show up dark-on-light, in dark mode light-on-dark
                    //      If doShowLightBackground,
                    //              in light mode, the scrollers show up light-on-light, in dark mode light-on-dark
                    // NOTE Changing the scrollview scroller knob style has no effect
                    self.renderTextView.backgroundColor = NSColor.hexToColour(common.paperColour)
                    self.renderTextScrollView.scrollerKnobStyle = .light //common.isLightMode ? .dark : .light

                    if let renderTextStorage: NSTextStorage = self.renderTextView.textStorage {
                        /*
                         * NSTextStorage subclasses that return true from the fixesAttributesLazily
                         * method should avoid directly calling fixAttributes(in:) or else bracket
                         * such calls with beginEditing() and endEditing() messages.
                         */
                        renderTextStorage.beginEditing()
                        renderTextStorage.setAttributedString(textAttString)
                        renderTextStorage.endEditing()
                        
                        // Add the subview to the instance's own view and draw
                        self.view.display()

                        // Call the QLPreviewingController indicating no error
                        // (argument is nil)
                        handler(nil)
                        return
                    }
                    
                    // We can't access the preview NSTextView's NSTextStorage
                    reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING)
                } else {
                    // We couldn't convert to data to a valid encoding
                    let errDesc: String = "\(BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_TS_STRING) \(encoding)"
                    reportError = NSError(domain: BUFFOON_CONSTANTS.APP_CODE_PREVIEWER,
                                          code: BUFFOON_CONSTANTS.ERRORS.CODES.BAD_MD_STRING,
                                          userInfo: [NSLocalizedDescriptionKey: errDesc])
                }
            } catch {
                // We couldn't read the file so set an appropriate error to report back
                reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN)
            }
        } else {
            // We couldn't access the file so set an appropriate error to report back
            reportError = setError(BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE)
        }

        // Display the error locally in the window
        showError(reportError!.userInfo[NSLocalizedDescriptionKey] as! String)

        // Call the QLPreviewingController indicating an error
        // (argumnet is not nil)
        handler(reportError)
    }
    
    
    // MARK:- Utility Functions
    
    /**
     Place an error message in its various outlets.
     
     - parameters:
        - errString: The error message.
     */
    func showError(_ errString: String) {

        NSLog("BUFFOON \(errString)")
        self.renderTextScrollView.isHidden = true
        self.previewErrorLabel.stringValue = errString
        self.previewErrorLabel.isHidden = false
        self.view.display()
    }
    
    
    /**
     Generate an NSError for an internal error, specified by its code.

     Codes are listed in `Constants.swift`

     - Parameters:
        - code: The internal error code.

     - Returns: The described error as an NSError.
     */
    func setError(_ code: Int) -> NSError {
        
        var errDesc: String
        
        switch(code) {
            case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_INACCESSIBLE:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_INACCESSIBLE
            case BUFFOON_CONSTANTS.ERRORS.CODES.FILE_WONT_OPEN:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.FILE_WONT_OPEN
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_TS_STRING:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_TS_STRING
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_MD_STRING:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_MD_STRING
            case BUFFOON_CONSTANTS.ERRORS.CODES.BAD_GO_CONFIG:
                errDesc = BUFFOON_CONSTANTS.ERRORS.MESSAGES.BAD_GO_CONFIG
            default:
                errDesc = "UNKNOWN ERROR"
        }

        return NSError(domain: BUFFOON_CONSTANTS.APP_CODE_PREVIEWER,
                       code: code,
                       userInfo: [NSLocalizedDescriptionKey: errDesc])
    }
    
    
    func getEncoding(_ enc: String.Encoding) -> String {
        
        if enc == .windowsCP1250 {
            return "Windows 1250"
        }
        
        if enc == .windowsCP1251 {
            return "Windows 1251"
        }
        
        if enc == .windowsCP1252 {
            return "Windows 1250"
        }
        
        if enc == .windowsCP1253 {
            return "Windows 1250"
        }
        
        if enc == .windowsCP1254 {
            return "Windows 1250"
        }
        
        if enc == .utf8 {
            return "UTF-8"
        }
        
        if enc == .utf16 {
            return "UTF-16"
        }
        
        if enc == .utf16LittleEndian {
            return "UTF-16 LE"
        }
        
        if enc == .utf16BigEndian {
            return "UTF-16 BE"
        }
        
        if enc == .macOSRoman {
            return "macOS Roman"
        }
        
        if enc == .ascii {
            return "Ascii"
        }
        
        if enc == .isoLatin1 {
            return "ISO Latin 1"
        }
        
        if enc == .isoLatin2 {
            return "ISO Latin 2"
        }
        
        if enc == .iso2022JP {
            return "ISO JP 2022"
        }
        
        if enc == .japaneseEUC {
            return "Japanese EUC"
        }
        
        if enc == .symbol {
            return "Symbol"
        }
        
        if enc == .shiftJIS {
            return "Shift JIS"
        }
        
        return "\(enc.rawValue)"
    }
    
    @IBAction private func selectEncoding(sender: Any) {
        
        let index = self.encodingOptions.indexOfSelectedItem
        switch(index) {
        default:
            self.loadView()
        }
    }
    
}
