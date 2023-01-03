/*
 *  Common.swift
 *  PreviewText
 *  Code common to Text Previewer and Text Thumbnailer
 *
 *  Created by Tony Smith on 05/10/2023.
 *  Copyright © 2023 Tony Smith. All rights reserved.
 */


import Foundation
import Cocoa
import AppKit


final class Common: NSObject {
    
    // MARK: - Public Properties
    
    var isLightMode: Bool               = true
    var inkColour: String               = BUFFOON_CONSTANTS.INK_COLOUR_HEX
    var paperColour: String             = BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
    var fontSize: CGFloat               = BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE
    var lineSpacing: CGFloat            = BUFFOON_CONSTANTS.BASE_LINE_SPACING
    
    // MARK: - Private Properties
    
    private var isThumbnail: Bool       = false
    private var alwaysLightMode: Bool   = false
    
    // String artifacts...
    private var textAtts: [NSAttributedString.Key: Any] = [:]
    private var hr: NSAttributedString                  = NSAttributedString.init(string: "")
    private var newLine: NSAttributedString             = NSAttributedString.init(string: "")
    
    var mainView: NSView? = nil
    
    // MARK:- Lifecycle Functions
    
    init(_ isThumbnail: Bool = false) {
        
        super.init()
        
        // Watch for macOS UI mode changes
        /*
        DistributedNotificationCenter.default.addObserver(self,
                                                          selector: #selector(interfaceModeChanged),
                                                          name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"),
                                                          object: nil)
        */
        
        // Set up instance properties
        self.isThumbnail = isThumbnail
        setProperties()
    }
    
    
    func setProperties(_ usePrefs: Bool = true, _ fontName: String = BUFFOON_CONSTANTS.BODY_FONT_NAME) {
        
        var baseFontName: String = fontName
        var baseInkColour: String = BUFFOON_CONSTANTS.INK_COLOUR_HEX
        var basePaperColour: String = BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
        
        // The suite name is the app group name, set in each extension's entitlements, and the host app's
        if usePrefs {
            if let prefs = UserDefaults(suiteName: MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME) {
                // First check the Mac's mode
                self.alwaysLightMode = prefs.bool(forKey: "com-bps-previewtext-do-use-light")
                
                // This should be true if we're rendering a thumbnail, the user wants
                // a dark-on-light preview even in Dark Mode, or the Mac is in Light Mode
                self.isLightMode = (isThumbnail || self.alwaysLightMode || isMacInLightMode())
                
                // Set current ink and paper colours
                baseInkColour = prefs.string(forKey: "com-bps-previewtext-ink-colour-hex") ?? BUFFOON_CONSTANTS.INK_COLOUR_HEX
                basePaperColour = prefs.string(forKey: "com-bps-previewtext-paper-colour-hex") ?? BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
                
                // Set the used colours according to the mode
                if isLightMode {
                    self.inkColour = baseInkColour
                    self.paperColour = basePaperColour
                } else {
                    self.inkColour = basePaperColour
                    self.paperColour = baseInkColour
                }
                
                // Get font sizes
                self.fontSize = isThumbnail
                    ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE
                    : CGFloat(prefs.float(forKey: "com-bps-previewtext-base-font-size"))
                baseFontName = prefs.string(forKey: "com-bps-previewtext-base-font-name") ?? BUFFOON_CONSTANTS.BODY_FONT_NAME
                
                // Set line spacing
                self.lineSpacing = CGFloat(prefs.float(forKey: "com-bps-previewtext-line-spacing")) 
            }
            
            // Just in case the above block reads in zero values
            // NOTE The other values CAN be zero
            if self.fontSize < CGFloat(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0]) ||
                self.fontSize > CGFloat(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1]) {
                self.fontSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
            }
        }
        
        // Create the font we'll use
        var font: NSFont
        if let chosenFont: NSFont = NSFont.init(name: baseFontName, size: self.fontSize) {
            font = chosenFont
        } else {
            font = NSFont.systemFont(ofSize: self.fontSize)
        }
        
        // Set up the attributed string components we may use during rendering
        let textParaStyle: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
        textParaStyle.lineSpacing = (self.lineSpacing - 1) * self.fontSize
        //textParaStyle.paragraphSpacing = self.lineSpacing * self.fontSize * 0.5
        
        self.textAtts = [
            .foregroundColor: NSColor.hexToColour(self.inkColour),
            .font: font,
            .paragraphStyle: textParaStyle
        ]
        
        self.hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                                     attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                                                  .strikethroughColor: NSColor.hexToColour(self.inkColour)]
        )
        
        self.newLine = NSAttributedString.init(string: "\n",
                                               attributes: textAtts)
    }
    
    
    // MARK:- The Primary Function
    
    /**
     Render the input JSON as an NSAttributedString.
     
     - Parameters:
     - textString: The path to the JSON code.
     
     - Returns: The rendered source as an NSAttributedString.
     */
    func getAttributedString(_ textString: String) -> NSAttributedString {
        
        // Set up the base string
        let renderedString: NSMutableAttributedString = NSMutableAttributedString.init(string: textString,
                                                                                       attributes: self.textAtts)
        return renderedString as NSAttributedString
    }
    
    
    /**
     Determine whether the host Mac is in light mode.
     
     - Returns: `true` if the Mac is in light mode, otherwise `false`.
     */
    private func isMacInLightMode() -> Bool {
        
        let appearNameString: String = NSApp.effectiveAppearance.name.rawValue
        return (appearNameString == "NSAppearanceNameAqua")
    }
    
    
    /**
     Handler for macOS UI mode change notifications
     */
    @objc private func interfaceModeChanged() {
        
        // Do nothing if we're thumbnailing...
        if !self.isThumbnail {
            // ...otherwise reset the properties
            setProperties()
        }
    }
}


/**
Get the encoding of the string formed from data.

- Returns: The string's encoding or nil.
*/

extension Data {
    
    var stringEncoding: String.Encoding? {
        var nss: NSString? = nil
        guard case let rawValue = NSString.stringEncoding(for: self,
                                                          encodingOptions: nil,
                                                          convertedString: &nss,
                                                          usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}

