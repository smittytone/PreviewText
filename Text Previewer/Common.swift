/*
 *  Common.swift
 *  PreviewText
 *  Code common to Text Previewer and Text Thumbnailer
 *
 *  Created by Tony Smith on 05/10/2023.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Foundation
import Cocoa
import AppKit
import UniformTypeIdentifiers


final class Common: NSObject {

    // MARK: - Public Properties

    var isLightMode: Bool               = true
    var inkColour: String               = BUFFOON_CONSTANTS.INK_COLOUR_HEX
    var paperColour: String             = BUFFOON_CONSTANTS.PAPER_COLOUR_HEX
    var fontSize: CGFloat               = BUFFOON_CONSTANTS.BASE_PREVIEW_FONT_SIZE
    var lineSpacing: CGFloat            = BUFFOON_CONSTANTS.BASE_LINE_SPACING
    // FROM 1.0.5
    var minimumTumbnailSize: Int        = BUFFOON_CONSTANTS.MIN_THUMB_SIZE

    /*
     Replace the following string with your own team ID. This is used to
     identify the app suite and so share preferences set by the main app with
     the previewer and thumbnailer extensions.
     */
    private var appSuiteName: String = MNU_SECRETS.PID + BUFFOON_CONSTANTS.SUITE_NAME


    // MARK: - Private Properties
    
    private var isThumbnail: Bool       = false
    private var alwaysLightMode: Bool   = false
    
    // String artifacts...
    private var textAtts: [NSAttributedString.Key: Any]     = [:]
    private var hr: NSAttributedString                      = NSAttributedString.init(string: "")
    private var newLine: NSAttributedString                 = NSAttributedString.init(string: "")
    // FROM 1.0.8
    private var debugAtts: [NSAttributedString.Key: Any]    = [:]


    // MARK:- Lifecycle Functions

    init(_ isThumbnail: Bool = false) {

        super.init()
        
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
            if let prefs = UserDefaults(suiteName: self.appSuiteName) {
                // First check the Mac's mode
                self.alwaysLightMode = prefs.bool(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_USE_LIGHT)

                // This should be true if we're rendering a thumbnail, the user wants
                // a dark-on-light preview even in Dark Mode, or the Mac is in Light Mode
                self.isLightMode = (isThumbnail || self.alwaysLightMode || isMacInLightMode())
                
                // Set current ink and paper colours
                baseInkColour = prefs.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_INK_COLOUR) ?? BUFFOON_CONSTANTS.INK_COLOUR_HEX
                basePaperColour = prefs.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_PAPER_COLOUR) ?? BUFFOON_CONSTANTS.PAPER_COLOUR_HEX

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
                    : CGFloat(prefs.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_SIZE))
                baseFontName = prefs.string(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_FONT_NAME) ?? BUFFOON_CONSTANTS.BODY_FONT_NAME

                // Set line spacing
                self.lineSpacing = isThumbnail
                    ? BUFFOON_CONSTANTS.BASE_THUMB_LINE_SPACING
                    : CGFloat(prefs.float(forKey: BUFFOON_CONSTANTS.PREFS_IDS.PREVIEW_LINE_SPACING))

                // FROM 1.0.5
                // Set minimum icon size
                self.minimumTumbnailSize = prefs.integer(forKey: BUFFOON_CONSTANTS.PREFS_IDS.THUMB_MIN_SIZE)
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
        textParaStyle.paragraphSpacing = 0.0
        
        self.textAtts = [
            .foregroundColor: NSColor.hexToColour(self.inkColour),
            .font: font,
            .paragraphStyle: textParaStyle
        ]
        
        self.debugAtts = [
            .foregroundColor: NSColor.systemRed,
            .font: font,
            .paragraphStyle: textParaStyle
        ]
        
        // Horizontal line
        // NOTE This formulation requires TextKit 1
        self.hr = NSAttributedString(string: "\n\u{00A0}\u{0009}\u{00A0}\n\n",
                                     attributes: [.strikethroughStyle: NSUnderlineStyle.thick.rawValue,
                                                  .strikethroughColor: NSColor.hexToColour(self.inkColour)]
        )
        
        // New line symbol
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
#if DEBUG
        let renderedString: NSMutableAttributedString = NSMutableAttributedString.init(string: textString,
                                                                                       attributes: self.textAtts)
        var encodingRange: NSRange = (textString as NSString).range(of: "PTDEBUG\n")
        if encodingRange.location != NSNotFound {
            encodingRange = NSMakeRange(0, encodingRange.location + 7)
            renderedString.setAttributes(self.debugAtts, range: encodingRange)
        }
#else
        let renderedString: NSMutableAttributedString = NSMutableAttributedString.init(string: textString,
                                                                                       attributes: self.textAtts)
#endif
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
    
    
    /**
     Get the supplied source file's UTI.

     We'll use it to determine the file's programming language.

     - Parameters:
        - sourceFilePath: The path to the source code file.

     - Returns: The source code's UTI.
    */
    func getSourceFileUTI(_ sourceFilePath: String) -> String {

        // Create a URL reference to the sample file
        var sourceFileUTI: String = ""
        let sourceFileURL = URL.init(fileURLWithPath: sourceFilePath)

        do {
            // Read back the UTI from the URL
            // Use Big Sur's UTType API
            if #available(macOS 11, *) {
                if let uti: UTType = try sourceFileURL.resourceValues(forKeys: [.contentTypeKey]).contentType {
                    sourceFileUTI = uti.identifier
                }
            } else {
                // NOTE '.typeIdentifier' yields an optional
                if let uti: String = try sourceFileURL.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier {
                    sourceFileUTI = uti
                }
            }
        } catch {
            // NOP
        }

        return sourceFileUTI
    }
}


/**
Get the encoding of the string formed from data.

- Returns: The string's encoding or nil.
*/

extension Data {
    
    var stringEncoding: String.Encoding? {
        
        guard case let rawValue = NSString.stringEncoding(for: self,
                                                          encodingOptions: nil,
                                                          convertedString: nil,
                                                          usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}

