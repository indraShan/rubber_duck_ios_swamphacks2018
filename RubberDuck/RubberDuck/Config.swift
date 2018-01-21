//
//  Config.swift
//  AVSExample
//

import Foundation

struct Config {
    
    struct LoginWithAmazon {
        static let ProductId = ""
        static let DeviceSerialNumber = ""
    }
    
    struct Debug {
        static let General = false
        static let Errors = true
        static let HTTPRequest = false
        static let HTTPResponse = false
    }
    
    struct Error {
        static let ErrorDomain = "com.indra.shan.dev.RubberDuck.Error.Domain"
        
        static let PCMSetupIncompleteErrorCode = 1
        
        static let AVSUploaderSetupIncompleteErrorCode = 2
        static let AVSAPICallErrorCode = 3
        static let AVSResponseBorderParseErrorCode = 4
    }

}
