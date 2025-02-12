/*
 *  Constants.swift
 *  PreviewText
 *
 *  Created by Tony Smith on 12/08/2020.
 *  Copyright © 2025 Tony Smith. All rights reserved.
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
            // FROM 1.0.2
            static let BAD_GO_CONFIG            = 404
        }

        struct MESSAGES {
            static let NO_ERROR                 = "No error"
            static let FILE_INACCESSIBLE        = "Can't access file"
            static let FILE_WONT_OPEN           = "Can't open file"
            static let BAD_MD_STRING            = "Can't get JSON data"
            static let BAD_TS_STRING            = "Can't access NSTextView's TextStorage"
            // FROM 1.0.2
            static let BAD_GO_CONFIG            = "This file is not a Go config file"
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

    static let BASE_PREVIEW_FONT_SIZE: CGFloat  = 16.0
    static let BASE_THUMB_FONT_SIZE: CGFloat    = 22.0
    static let THUMBNAIL_LINE_COUNT             = 32

    static let FONT_SIZE_OPTIONS: [CGFloat]     = [10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 28.0]
    static let PREVIEW_SIZE_OPTIONS: [CGFloat]  = [9.0,  11.0, 13.0, 15.0, 17.0, 19.0, 22.0]

    static let BASE_LINE_SPACING: CGFloat       = 1.0

    static let URL_MAIN                         = "https://smittytone.net/previewtext/index.html"
    static let APP_STORE                        = "https://apps.apple.com/us/app/previewtext/id1660037028"
    static let SUITE_NAME                       = ".suite.preview-previewtext"
    static let APP_CODE_PREVIEWER               = "com.bps.previewtext.Text_Previewer"

    static let BODY_FONT_NAME                   = "Menlo-Regular"
    static let INK_COLOUR_HEX                   = "000000FF"
    static let PAPER_COLOUR_HEX                 = "FFFFFFFF"

    static let RENDER_DEBUG                     = false

    static let FILE_CODE_SAMPLE                 = "text-sample"

    struct APP_URLS {

        static let PM                           = "https://apps.apple.com/us/app/previewmarkdown/id1492280469?ls=1"
        static let PC                           = "https://apps.apple.com/us/app/previewcode/id1571797683?ls=1"
        static let PY                           = "https://apps.apple.com/us/app/previewyaml/id1564574724?ls=1"
        static let PJ                           = "https://apps.apple.com/us/app/previewjson/id6443584377?ls=1"
        static let PT                           = "https://apps.apple.com/us/app/previewtext/id1660037028?ls=1"
    }

    // FROM 1.0.5
    static let MIN_THUMB_SIZE                   = 48
    static let BASE_THUMB_LINE_SPACING          = 1.15
    static let THUMB_SIZES: [Int]               = [256, 128, 96, 64, 48, 32, 16]

    struct PREFS_IDS {

        static let MAIN_WHATS_NEW               = "com-bps-previewtext-do-show-whats-new-"
        static let PREVIEW_FONT_SIZE            = "com-bps-previewtext-base-font-size"
        static let PREVIEW_FONT_NAME            = "com-bps-previewtext-base-font-name"
        static let PREVIEW_LINE_SPACING         = "com-bps-previewtext-line-spacing"
        static let PREVIEW_PAPER_COLOUR         = "com-bps-previewtext-paper-colour-hex"
        static let PREVIEW_INK_COLOUR           = "com-bps-previewtext-ink-colour-hex"
        static let PREVIEW_USE_LIGHT            = "com-bps-previewtext-do-use-light"
        static let THUMB_MIN_SIZE               = "com-bps-previewtext-min-thumb-size"
        static let THUMB_FONT_SIZE              = "com-bps-previewtext-thumb-font-size"
    }
}
