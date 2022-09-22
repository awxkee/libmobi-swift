//
//  Mobi.swift
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

import Foundation
import libmobic

public class Mobi {

    private let driver: MobiDriver

    public init(url: URL) throws {
        driver = try MobiFileDriver(url: url)
    }

    public func createEpub(dstEpub: URL) throws {
        guard let rawml = mobi_init_rawml(driver.getMOBIData()) else {
            throw MobiFetchingRAWMLError()
        }
        let ret = mobi_parse_rawml(rawml, driver.getMOBIData())
        if ret != MOBI_SUCCESS {
            mobi_free_rawml(rawml)
            throw MobiFetchingRAWMLError()
        }
        let pathCChar = FileManager.default.fileSystemRepresentation(withPath: dstEpub.path)
        let status = create_epub(rawml, pathCChar)
        if status != MOBI_TOOLCHAIN_SUCCESS {
            mobi_free_rawml(rawml)
            throw MobiEpubCraetingError(url: dstEpub)
        }
        mobi_free_rawml(rawml)
    }

    public func dumpSource(dstFolder: URL) throws {
        guard let rawml = mobi_init_rawml(driver.getMOBIData()) else {
            throw MobiFetchingRAWMLError()
        }
        let ret = mobi_parse_rawml(rawml, driver.getMOBIData())
        if ret != MOBI_SUCCESS {
            mobi_free_rawml(rawml)
            throw MobiFetchingRAWMLError()
        }
        let pathCChar = FileManager.default.fileSystemRepresentation(withPath: dstFolder.path)
        let status = dump_rawml_parts(rawml, pathCChar)
        if status != MOBI_TOOLCHAIN_SUCCESS {
            mobi_free_rawml(rawml)
            throw MobiEpubCraetingError(url: dstFolder)
        }
        mobi_free_rawml(rawml)
    }

    public func dumpRawml(dst: URL) throws {
        let pathCChar = FileManager.default.fileSystemRepresentation(withPath: dst.path)
        guard let dstFile = fopen(pathCChar, "wb") else {
            throw MobiOpeningFileError(url: dst)
        }
        let ret = mobi_dump_rawml(driver.getMOBIData(), dstFile)
        if ret != MOBI_SUCCESS {
            fclose(dstFile)
            throw MobiDumpRAWMLError()
        }
        fclose(dstFile)
    }

    public func getRawml() throws -> String {
        let mobiData = driver.getMOBIData()
        let maxSize = mobi_get_text_maxsize(mobiData)
        if maxSize == MOBI_NOTSET {
            throw MobiBookStructureError(string: "Cannot initialize mobi text size")
        }
        var capacity = Int(maxSize + 1)
        let cFeature = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
        defer { cFeature.deallocate() }
        let ret = mobi_get_rawml(mobiData, cFeature, &capacity)
        if ret != MOBI_SUCCESS {
            throw MobiFetchingRAWMLError()
        }
        let data = Data(bytes: cFeature, count: capacity)
        let encoding: String.Encoding
        if mobiData.pointee.mh.pointee.text_encoding.pointee == MOBI_UTF8 {
            encoding = .utf8
        } else if mobiData.pointee.mh.pointee.text_encoding.pointee == MOBI_CP1252 {
            encoding = .windowsCP1252
        } else if mobiData.pointee.mh.pointee.text_encoding.pointee == MOBI_UTF16 {
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
        let mobiData = driver.getMOBIData()
        guard let exth = mobi_get_exthrecord_by_tag(mobiData, EXTH_COVEROFFSET) else {
            return nil
        }
        let offset = mobi_decode_exthvalue(exth.pointee.data, Int(exth.pointee.size))
        let firstResource = mobi_get_first_resource_record(mobiData)
        let uid = firstResource + Int(offset);
        let record = mobi_get_record_by_seqnumber(mobiData, uid)
        guard let record, record.pointee.size >= 4 else {
            return nil
        }
        return Data(bytes: record.pointee.data, count: record.pointee.size)
    }
}
