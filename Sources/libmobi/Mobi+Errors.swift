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
    public var errorDescription: String? {
        "Cannot open provided file"
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
