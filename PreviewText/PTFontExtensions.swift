/*
 *  GenericExtensions.swift
 *  PreviewMarkdown/PreviewText
 *
 *  These functions can be used by all PreviewApps
 *
 *  Created by Tony Smith on 18/06/2021.
 *  Copyright © 2025 Tony Smith. All rights reserved.
 */


import Foundation
import Cocoa
import WebKit
import UniformTypeIdentifiers


extension AppDelegate {

    // MARK: - Font Management

    /**
     Build a list of available fonts.

     Should be called asynchronously. Two sets created: monospace fonts and regular fonts.
     Requires 'bodyFonts' and 'codeFonts' to be set as instance properties.
     Comment out either of these, as required.

     The final font lists each comprise pairs of strings: the font's PostScript name
     then its display name.
     */
    internal func asyncGetFonts() {

        var bf: [PMFont] = []

        let mono: UInt = NSFontTraitMask.fixedPitchFontMask.rawValue
        let bold: UInt = NSFontTraitMask.boldFontMask.rawValue
        let ital: UInt = NSFontTraitMask.italicFontMask.rawValue
        let symb: UInt = NSFontTraitMask.nonStandardCharacterSetFontMask.rawValue

        let fm: NSFontManager = NSFontManager.shared

        let families: [String] = fm.availableFontFamilies
        for family in families {
            // Remove known unwanted fonts
            if family.hasPrefix(".") || family.hasPrefix("Apple Braille") || family == "Apple Color Emoji" {
                continue
            }

            // For each family, examine its fonts for suitable ones
            if let fonts: [[Any]] = fm.availableMembers(ofFontFamily: family) {
                // This will hold a font family: individual fonts will be added to
                // the 'styles' array
                var familyRecord: PMFont = PMFont.init()
                familyRecord.displayName = family

                for font: [Any] in fonts {
                    let psname: String = font[0] as! String
                    let traits: UInt = font[3] as! UInt
                    var doUseFont: Bool = false

                    if mono & traits != 0 {
                        doUseFont = true
                    } else if traits & bold == 0 && traits & ital == 0 && traits & symb == 0 {
                        doUseFont = true
                    }

                    if doUseFont {
                        // The font is good to use, so add it to the list
                        var fontRecord: PMFont = PMFont.init()
                        fontRecord.postScriptName = psname
                        fontRecord.styleName = font[1] as! String
                        fontRecord.traits = traits

                        if familyRecord.styles == nil {
                            familyRecord.styles = []
                        }

                        familyRecord.styles!.append(fontRecord)
                    }
                }

                if familyRecord.styles != nil && familyRecord.styles!.count > 0 {
                    bf.append(familyRecord)
                }
            }
        }

        DispatchQueue.main.async {
            self.bodyFonts = bf
        }
    }


    /**
     Build and enable the font style popup.

     - Parameters:
        - isBody:    Whether we're handling body text font styles (`true`) or code font styles (`false`). Default: `true`.
        - styleName: The name of the selected style. Default: `nil`.
     */
    internal func setStylePopup(_ styleName: String? = nil) {

        let selectedFamily: String = self.codeFontPopup.titleOfSelectedItem!
        let familyList: [PMFont] = self.bodyFonts
        let targetPopup: NSPopUpButton = self.codeStylePopup
        targetPopup.removeAllItems()

        for family: PMFont in familyList {
            if selectedFamily == family.displayName {
                if let styles: [PMFont] = family.styles {
                    targetPopup.isEnabled = true
                    for style: PMFont in styles {
                        targetPopup.addItem(withTitle: style.styleName)
                    }

                    if styleName != nil {
                        targetPopup.selectItem(withTitle: styleName!)
                    }
                }
            }
        }
    }


    /**
     Select the font popup using the stored PostScript name
     of the user's chosen font.

     - Parameters:
        - postScriptName: The PostScript name of the font.
        - isBody:         Whether we're handling body text font styles (`true`) or code font styles (`false`).
     */
    internal func selectFontByPostScriptName(_ postScriptName: String) {

        let familyList: [PMFont] = self.bodyFonts
        let targetPopup: NSPopUpButton = self.codeFontPopup

        for family: PMFont in familyList {
            if let styles: [PMFont] = family.styles {
                for style: PMFont in styles {
                    if style.postScriptName == postScriptName {
                        targetPopup.selectItem(withTitle: family.displayName)
                        setStylePopup(style.styleName)
                    }
                }
            }
        }
    }


    /**
     Get the PostScript name from the selected family and style.

     - Parameters:
        - isBody: Whether we're handling body text font styles (`true`) or code font styles (`false`).

     - Returns: The PostScript name as a string, or nil.
     */
    internal func getPostScriptName() -> String? {

        let familyList: [PMFont] = self.bodyFonts
        let fontPopup: NSPopUpButton = self.codeFontPopup
        let stylePopup: NSPopUpButton = self.codeStylePopup

        if let selectedFont: String = fontPopup.titleOfSelectedItem {
            let selectedStyle: Int = stylePopup.indexOfSelectedItem

            for family: PMFont in familyList {
                if family.displayName == selectedFont {
                    if let styles: [PMFont] = family.styles {
                        let font: PMFont = styles[selectedStyle]
                        return font.postScriptName
                    }
                }
            }
        }

        return nil
    }
}
