/*
 *  Constants.swift
 *  PreviewJson
 *
 *  Created by Tony Smith on 12/08/2020.
 *  Copyright © 2022 Tony Smith. All rights reserved.
 */


import Foundation


// Combine the app's various constants into a struct
struct BUFFOON_CONSTANTS {

    struct ERRORS {

        struct CODES {
            static let NONE                     = 0
            static let FILE_INACCESSIBLE        = 400
            static let FILE_WONT_OPEN           = 401
            static let BAD_MD_STRING            = 402
            static let BAD_TS_STRING            = 403
        }

        struct MESSAGES {
            static let NO_ERROR                 = "No error"
            static let FILE_INACCESSIBLE        = "Can't access file"
            static let FILE_WONT_OPEN           = "Can't open file"
            static let BAD_MD_STRING            = "Can't get JSON data"
            static let BAD_TS_STRING            = "Can't access NSTextView's TextStorage"
        }
    }

    struct THUMBNAIL_SIZE {

        static let ORIGIN_X                     = 0
        static let ORIGIN_Y                     = 0
        static let WIDTH                        = 768
        static let HEIGHT                       = 1024
        static let ASPECT                       = 0.75
        static let TAG_HEIGHT                   = 204.8
        static let FONT_SIZE                    = 130.0
    }
    
    struct ITEM_TYPE {
        
        static let KEY                          = 0
        static let VALUE                        = 1
        static let MARK_START                   = 2
        static let MARK_END                     = 3
    }
    
    struct BOOL_STYLE {
        
        static let FULL                         = 0
        static let OUTLINE                      = 1
        static let TEXT                         = 2
    }

    static let BASE_PREVIEW_FONT_SIZE: Float    = 16.0
    static let BASE_THUMB_FONT_SIZE: Float      = 22.0
    static let THUMBNAIL_LINE_COUNT             = 38
    
    static let FONT_SIZE_OPTIONS: [CGFloat]     = [10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 28.0]

    static let JSON_INDENT                      = 8     // Can change
    static let BASE_INDENT                      = 2     // Fixed

    static let URL_MAIN                         = "https://smittytone.net/previewtext/index.html"
    static let APP_STORE                        = "https://apps.apple.com/us/app/previewtext/idXXXXXXXX"
    static let SUITE_NAME                       = ".suite.preview-previewtext"
    static let APP_CODE_PREVIEWER               = "com.bps.previewtext.Text_Previewer"
    
    static let BODY_FONT_NAME                   = "Menlo-Regular"
    static let BODY_COLOUR_HEX                  = "FF2600FF"
    static let BACK_COLOUR_HEX                  = "929292FF"
    
    static let RENDER_DEBUG                     = false
}
