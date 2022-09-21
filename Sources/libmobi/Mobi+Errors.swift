//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

import Foundation

public struct MobiInitializationError: LocalizedError {
    public var errorDescription: String? {
        "Cannot initialize library"
    }
}

public struct MobiOpeningFileError: LocalizedError {
    let url: URL
    public var errorDescription: String? {
        "Cannot open provided file \(url.absoluteString)"
    }
}

public struct MobiBookOpeningError: LocalizedError {
    public var errorDescription: String? {
        "libmobi cannot open provided file"
    }
}

public struct MobiFetchingRAWMLError: LocalizedError {
    public var errorDescription: String? {
        "libmobi cannot resolve rawml data"
    }
}

public struct MobiDumpRAWMLError: LocalizedError {
    public var errorDescription: String? {
        "libmobi cannot dump rawml data"
    }
}

public struct MobiBookStructureError: LocalizedError {
    let string: String

    public var errorDescription: String? {
        string
    }
}

public struct MobiEpubCraetingError: LocalizedError {
    
    let url: URL

    public var errorDescription: String? {
        "libmobi cannot create epub to \(url.absoluteString)"
    }
}
