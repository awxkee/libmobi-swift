//
//  File.swift
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

import Foundation
import libmobic

class MobiFileDriver: MobiDriver {

    private var mobiData: UnsafeMutablePointer<MOBIData>?
    private var file: UnsafeMutablePointer<FILE>?

    public init(url: URL) throws {
        guard let data = mobi_init() else {
            throw MobiInitializationError()
        }
        self.mobiData = data
        let pathCChar = FileManager.default.fileSystemRepresentation(withPath: url.path)
        guard let newFile = fopen(pathCChar, "rb") else {
            throw MobiOpeningFileError(url: url)
        }
        self.file = newFile
        let ret = mobi_load_file(mobiData, file)
        if ret != MOBI_SUCCESS {
            if let file {
                fclose(file)
                self.file = nil
            }
            if let mobiData {
                mobi_free(mobiData)
                self.mobiData = nil
            }
            throw MobiBookOpeningError()
        }
    }

    func getMOBIData() -> UnsafeMutablePointer<MOBIData> {
        return mobiData!
    }

    deinit {
        if let file {
            fclose(file)
            self.file = nil
        }
        if let mobiData {
            mobi_free(mobiData)
            self.mobiData = nil
        }
    }
}
