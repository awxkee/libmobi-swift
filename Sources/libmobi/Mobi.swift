//
//  Mobi.swift
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

import Foundation
import libmobic

public class Mobi {

    private var mobiData: MOBIData
    private var file: FILE

    public init(url: URL) throws {
        guard let data = mobi_init() else {
            throw MobiInitializationError()
        }
        self.mobiData = data.pointee
        var pathCChar = url.path.utf8CString
        var paramsCChar = "rb".utf8CString
        guard let newFile = fopen(&pathCChar, &paramsCChar) else {
            mobi_free(&mobiData)
            throw MobiOpeningFileError()
        }
        self.file = newFile.pointee
        let ret = mobi_load_file(&mobiData, &file)
        if ret != MOBI_SUCCESS {
            free(&file)
            mobi_free(&mobiData)
            throw MobiBookOpeningError()
        }
    }

    public func dumpRawml(dst: URL) throws {
        var pathCChar = dst.path.utf8CString
        var paramsCChar = "wb".utf8CString
        guard let dstFile = fopen(&pathCChar, &paramsCChar) else {
            throw MobiOpeningFileError()
        }
        let ret = mobi_dump_rawml(&mobiData, dstFile)
        if ret != MOBI_SUCCESS {
            fclose(dstFile)
            throw MobiDumpRAWMLError()
        }
        fclose(dstFile)
    }

    public func getRawml() throws -> String {
        var capacity = Int(mobiData.rh.pointee.text_length)
        var cFeature = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
        defer { cFeature.deallocate() }
        let ret = mobi_get_rawml(&mobiData, &cFeature, &capacity)
        if ret != MOBI_SUCCESS {
            throw MobiFetchingRAWMLError()
        }
        let data = Data(bytes: cFeature, count: capacity)
        let encoding: String.Encoding
        if mobiData.mh.pointee.text_encoding.pointee == MOBI_UTF8 {
            encoding = .utf8
        } else if mobiData.mh.pointee.text_encoding.pointee == MOBI_CP1252 {
            encoding = .windowsCP1252
        } else if mobiData.mh.pointee.text_encoding.pointee == MOBI_UTF16 {
            encoding = .utf16
        } else {
            encoding = .utf8
        }
        guard let string = String(data: data, encoding: encoding) else {
            throw MobiFetchingRAWMLError()
        }
        return string
    }

    public func getCover() throws -> Data? {
        guard let exth = mobi_get_exthrecord_by_tag(&mobiData, EXTH_COVEROFFSET) else {
            return nil
        }
        let offset = mobi_decode_exthvalue(exth.pointee.data, Int(exth.pointee.size))
        let firstResource = mobi_get_first_resource_record(&mobiData)
        let uid = firstResource + Int(offset);
        let record = mobi_get_record_by_seqnumber(&mobiData, uid)
        guard let record, record.pointee.size < 4 else {
            return nil
        }
        return Data(bytes: record.pointee.data, count: record.pointee.size)
    }

    deinit {
        fclose(&file)
        mobi_free(&mobiData)
    }
}
