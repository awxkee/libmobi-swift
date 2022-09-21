//
//  MobiDriver.swift
//  
//
//  Created by Radzivon Bartoshyk on 21/09/2022.
//

import Foundation
import libmobic

protocol MobiDriver: AnyObject {
    func getMOBIData() -> UnsafeMutablePointer<MOBIData>
}
