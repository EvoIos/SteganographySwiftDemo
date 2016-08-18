//
//  RGB32.swift
//  SteganographySwiftDemo
//
//  Created by zhenglanchun on 16/8/18.
//  Copyright © 2016年 LC. All rights reserved.
//

import Foundation
import CoreImage

struct RGBA32: Equatable {
    var color: UInt32
    
    var red: UInt8 {
        return UInt8((color >> 24) & 255)
    }
    
    var green: UInt8 {
        return UInt8((color >> 16) & 255)
    }
    
    var blue: UInt8 {
        return UInt8((color >> 8) & 255)
    }
    
    var alpha: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let bitmapInfo = CGImageAlphaInfo.PremultipliedLast.rawValue | CGBitmapInfo.ByteOrder32Little.rawValue
}

func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
    return lhs.color == rhs.color
}
