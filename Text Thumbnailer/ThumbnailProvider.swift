/*
 *  ThumbnailProvider.swift
 *  PreviewJson
 *
 *  Created by Tony Smith on 01/09/2022.
 *  Copyright © 2022 Tony Smith. All rights reserved.
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
        case badGfxBitmap
        case badGfxDraw
    }
    

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {

        /*
         * This is the main entry point for macOS' thumbnailing system
         */
        
        let iconScale: CGFloat = request.scale
        let thumbnailFrame: CGRect = NSMakeRect(0.0,
                                                0.0,
                                                CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ASPECT) * request.maximumSize.height,
                                                request.maximumSize.height)
        
        handler(QLThumbnailReply.init(contextSize: thumbnailFrame.size) { (context) -> Bool in
            // Place all the remaining code within the closure passed to 'handler()'
            
            let result: Result<Bool, ThumbnailerError> = autoreleasepool { () -> Result<Bool, ThumbnailerError> in
            
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
                            return .failure(ThumbnailerError.badFileLoad(request.fileURL.path))
                        }

                        // Instantiate the common code within the closure
                        let common: Common = Common.init(true)
                        
                        // Only render the lines likely to appear in the thumbnail
                        let lines: [String] = (textFileString as NSString).components(separatedBy: "\n")
                        var shortString: String = ""
                        for i in 0..<lines.count {
                            // Break at line THUMBNAIL_LINE_COUNT
                            if i >= BUFFOON_CONSTANTS.THUMBNAIL_LINE_COUNT { break }
                            shortString += (lines[i] + "\n")
                        }
                        
                        // Get the Attributed String
                        let textAtts: NSAttributedString = common.getAttributedString(shortString)

                        // Set the primary drawing frame and a base font size
                        let textFrame: CGRect = NSMakeRect(CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_X),
                                                           CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.ORIGIN_Y),
                                                           CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.WIDTH),
                                                           CGFloat(BUFFOON_CONSTANTS.THUMBNAIL_SIZE.HEIGHT))

                        // Instantiate an NSTextField to display the NSAttributedString render of the code
                        let textTextField: NSTextField = NSTextField.init(labelWithAttributedString: textAtts)
                        textTextField.frame = textFrame

                        // Generate the bitmap from the rendered code text view
                        guard let bodyImageRep: NSBitmapImageRep = textTextField.bitmapImageRepForCachingDisplay(in: textFrame) else {
                            return .failure(ThumbnailerError.badGfxBitmap)
                        }

                        // Draw the code view into the bitmap
                        textTextField.cacheDisplay(in: textFrame, to: bodyImageRep)
                        
                        // Alternative drawing code to make use of a supplied context
                        // NOTE 'context' passed in by the caller, ie. macOS QL server
                        var drawResult: Bool = false
                        let scaleFrame: CGRect = NSMakeRect(0.0,
                                                            0.0,
                                                            thumbnailFrame.width * iconScale,
                                                            thumbnailFrame.height * iconScale)
                        if let image: CGImage = bodyImageRep.cgImage {
                            context.draw(image, in: scaleFrame, byTiling: false)
                            drawResult = true
                        }

                        // Not sure why this is needed -- not using CA -- but it seems to help
                        CATransaction.commit()

                        if drawResult {
                            return .success(true)
                        } else {
                            return .failure(ThumbnailerError.badGfxDraw)
                        }
                    } catch {
                        // NOP: fall through to error
                    }
                }

                // We didn't draw anything because of 'can't find file' error
                return .failure(ThumbnailerError.badFileUnreadable(request.fileURL.path))
            }

            // Pass the outcome up from out of the autorelease
            // pool code to the handler as a bool, logging an error
            // if appropriate
            
            switch result {
                case .success(_):
                    return true
                case .failure(let error):
                    switch error {
                        case .badFileUnreadable(let filePath):
                            NSLog("Could not access file \(filePath)")
                        case .badFileLoad(let filePath):
                            fallthrough
                        case .badFileUnsupportedEncoding(let filePath):
                            NSLog("Could not render file \(filePath)")
                        default:
                            NSLog("Could not render thumbnail")
                    }
            }

            return false
        }, nil)
    }

}
