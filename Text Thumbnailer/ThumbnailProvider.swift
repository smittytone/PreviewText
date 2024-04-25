/*
 *  ThumbnailProvider.swift
 *  PreviewText
 *
 *  Created by Tony Smith on 01/09/2023.
 *  Copyright © 2023 Tony Smith. All rights reserved.
 */


import Foundation
import AppKit
import QuickLookThumbnailing


class ThumbnailProvider: QLThumbnailProvider {

    // MARK:- Private Properties
    
    private enum ThumbnailerError: Error {
        case badFileLoad(String)
        case badFileUnreadable(String)
        case badFileUnsupportedEncoding(String)
        case badFileUnsupportedFile(String)
        case badGfxBitmap
        case badGfxDraw
    }


    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {

        /*
         * This is the main entry point for macOS' thumbnailing system
         */

        // FROM 1.0.5
        // Don't bother rendering if the required icon size is
        // too small to see. Set by the user, but 63 pixels or less by default
        let common: Common = Common.init(true)
        if Double(common.minimumTumbnailSize) > request.maximumSize.height {
            handler(nil, ThumbnailerError.badFileUnsupportedFile("ICON SIZE BELOW MINIMUM"))
            return
        }

        // Load the source file using a co-ordinator as we don't know what thread this function
        // will be executed in when it's called by macOS' QuickLook code
        if FileManager.default.isReadableFile(atPath: request.fileURL.path) {
            // Only proceed if the file is accessible from here
            do {
                // Get the file contents as a string, making sure it's not cached
                // as we're not going to read it again any time soon
                let data: Data = try Data.init(contentsOf: request.fileURL, options: [.uncached])

                // Get the string's encoding, or fail back to .utf8
                let encoding: String.Encoding = data.stringEncoding ?? .utf8

                guard let textFileString: String = String.init(data: data, encoding: encoding) else {
                    handler(nil, ThumbnailerError.badFileLoad(request.fileURL.path))
                    return
                }

                // FROM 1.0.2
                // Get the UTI to check Go config files
                let sourceFileUTI: String = common.getSourceFileUTI(request.fileURL.path).lowercased()
                if sourceFileUTI == "com.bps.goconfig" {
                    if !request.fileURL.lastPathComponent.starts(with: "go.") {
                        handler(nil, ThumbnailerError.badFileUnsupportedFile("Not a Go config file"))
                        return
                    }
                }

                // Only render the lines likely to appear in the thumbnail: split into 32 substrings, assuming one per line
                let lines: [Substring] = textFileString.split(separator: "\n", maxSplits: BUFFOON_CONSTANTS.THUMBNAIL_LINE_COUNT + 1, omittingEmptySubsequences: false)
                var displayString: String = ""
                var displayLineCount: Int = 0
                for i in 0..<lines.count {
                    // Split the line into words and count them (approx.)
                    let words: [Substring] = lines[i].split(separator: " ")
                    let approxParagraphLineCount: Int = words.count / 12
                    
                    // Estimate the number of lines the paragraph requires
                    if approxParagraphLineCount > 1 {
                        displayLineCount += (approxParagraphLineCount + 1)
                    } else {
                        displayLineCount += 1
                    }
                    
                    // Add the paragraph to the string we'll present
                    displayString += (String(lines[i]) + "\n")

                    if displayLineCount >= BUFFOON_CONSTANTS.THUMBNAIL_LINE_COUNT {
                        break
                    }
                }

                // Get the Attributed String from the base string
                let textAtts: NSAttributedString = common.getAttributedString(displayString)

                // Set the primary drawing frame and a base font size
                let textFrame: CGRect = NSMakeRect(CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH),
                                                   CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.HEIGHT))

                // Instantiate an NSTextField to display the NSAttributedString render of the text
                let textTextField = NSTextField.init(frame: textFrame)
                textTextField.attributedStringValue = textAtts

                // Generate the bitmap from the rendered code text view
                guard let bodyImageRep: NSBitmapImageRep = textTextField.bitmapImageRepForCachingDisplay(in: textFrame) else {
                    handler(nil, ThumbnailerError.badGfxBitmap)
                    return
                }

                // Draw the code view into the bitmap
                textTextField.cacheDisplay(in: textFrame, to: bodyImageRep)
                
                if let image: CGImage = bodyImageRep.cgImage {
                    // Just in case, make a copy of the cgImage, in case
                    // `bodyImageReg` is freed
                    if let cgImage: CGImage = image.copy() {
                        // Calculate image scaling, frame size, etc.
                        let iconScale: CGFloat = request.scale
                        let thumbnailFrame: CGRect = NSMakeRect(0.0,
                                                                0.0,
                                                                CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ASPECT) * request.maximumSize.height,
                                                                request.maximumSize.height)
                        let scaleFrame: CGRect = NSMakeRect(0.0,
                                                            0.0,
                                                            thumbnailFrame.width * iconScale,
                                                            thumbnailFrame.height * iconScale)
                        
                        // Pass a QLThumbnailReply and no error to the supplied handler
                        handler(QLThumbnailReply.init(contextSize: thumbnailFrame.size) { (context) -> Bool in
                            // `scaleFrame` and `cgImage` are immutable
                            context.draw(cgImage, in: scaleFrame, byTiling: false)
                            return true
                        }, nil)
                        return
                    }
                }

                handler(nil, ThumbnailerError.badGfxDraw)
                return
            } catch {
                // NOP: fall through to error
            }
        }

        // We didn't draw anything because of 'can't find file' error
        handler(nil, ThumbnailerError.badFileUnreadable(request.fileURL.path))
    }
}
