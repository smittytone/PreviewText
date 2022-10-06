/*
 *  Common.swift
 *  PreviewText
 *  Code common to Text Previewer and Text Thumbnailer
 *
 *  Created by Tony Smith on 05/10/2022.
 *  Copyright © 2022 Tony Smith. All rights reserved.
 */


import Foundation
import AppKit


final class Common: NSObject {
    
    // MARK: - Public Properties
    
    var doShowLightBackground: Bool = false
    var backgroundColour: String    = BUFFOON_CONSTANTS.BACK_COLOUR_HEX
    var foregroundColour: String    = BUFFOON_CONSTANTS.BODY_COLOUR_HEX
    var isLightMode:Bool            = true
    
    // MARK: - Private Properties
    
    private var isThumbnail:Bool    = false
    private var fontSize: CGFloat   = 0
    
    // String artifacts...
    private var textAtts: [NSAttributedString.Key: Any] = [:]
    private var hr: NSAttributedString                  = NSAttributedString.init(string: "")
    private var newLine: NSAttributedString             = NSAttributedString.init(string: "")
    
    
    // MARK:- Lifecycle Functions
    
    init(_ isThumbnail: Bool = false) {
        
        super.init()
        
        let appearance: NSAppearance = NSApp.effectiveAppearance
        if let appearName: NSAppearance.Name = appearance.bestMatch(from: [.aqua, .darkAqua]) {
            self.isLightMode = (appearName != .aqua)
        }
        
        var fontBaseSize: CGFloat = CGFloat(BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
        var fontBaseName: String  = BUFFOON_CONSTANTS.BODY_FONT_NAME
        
        self.isThumbnail = isThumbnail
        
        // The suite name is the app group name, set in each extension's entitlements, and the host app's
        if let prefs = UserDefaults(suiteName: MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME) {
            self.doShowLightBackground  = prefs.bool(forKey: "com-bps-previewtext-do-use-light")
            
            fontBaseSize = CGFloat(isThumbnail
                                   ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE
                                   : prefs.float(forKey: "com-bps-previewtext-base-font-size"))
            fontBaseName = prefs.string(forKey: "com-bps-previewtext-base-font-name") ?? BUFFOON_CONSTANTS.BODY_FONT_NAME
            self.foregroundColour = prefs.string(forKey: "com-bps-previewtext-code-colour-hex") ?? BUFFOON_CONSTANTS.BODY_COLOUR_HEX
            self.backgroundColour = prefs.string(forKey: "com-bps-previewtext-mark-colour-hex") ?? BUFFOON_CONSTANTS.BACK_COLOUR_HEX
        }
        
        // Just in case the above block reads in zero values
        // NOTE The other values CAN be zero
        if fontBaseSize < CGFloat(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[0]) ||
            fontBaseSize > CGFloat(BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS[BUFFOON_CONSTANTS.FONT_SIZE_OPTIONS.count - 1]) {
            fontBaseSize = CGFloat(isThumbnail ? BUFFOON_CONSTANTS.BASE_THUMB_FONT_SIZE : BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE)
        }
        
        // Set the YAML key:value fonts and sizes
        var font: NSFont
        if let chosenFont: NSFont = NSFont.init(name: fontBaseName, size: fontBaseSize) {
            font = chosenFont
        } else {
            font = NSFont.systemFont(ofSize: fontBaseSize)
        }
        
        self.fontSize = fontBaseSize
        
        // Set up the attributed string components we may use during rendering
        let markParaStyle: NSMutableParagraphStyle = NSMutableParagraphStyle.init()
        markParaStyle.paragraphSpacing = fontBaseSize * 0.85
        
        self.textAtts = [
            .foregroundColor: (isThumbnail || self.doShowLightBackground || self.isLightMode ?
                               NSColor.hexToColour(self.foregroundColour) :
                               NSColor.hexToColour(self.backgroundColour)),
            .font: font,
            .paragraphStyle: markParaStyle
        ]
        
        self.hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                                     attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                                                  .strikethroughColor: (isThumbnail || self.doShowLightBackground ? NSColor.black : NSColor.white)])
        
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
