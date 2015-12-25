//
//  Utils.swift
//  mysql_driver
//
//  Created by cipi on 19/12/15.
//  Copyright © 2015 cipi. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


extension MySQL {
    
    internal struct Utils {
        static func skipLenEncStr(data:[UInt8]) -> Int {
            var (num, n) = lenEncInt(data)
            
            guard num != nil else {
                return 0
            }
            
            if num < 1 {
                return n
            }
            
            n += Int(num!)
            
            if data.count >= n {
                return n
            }
            return n
        }
        
        static func lenEncStr(b:[UInt8]) ->(String?, Int) {
            
            var (num, n) = lenEncInt(b)
            
            guard num != nil else {
                return (nil, 0)
            }
            
            if num < 1 {
                
                return ("", n)
            }
            
            n += Int(num!)
            
            if b.count >= n {
                var str = Array(b[n-Int(num!)...n-1])
                str.append(0)
                return (str.string(), n)
            }
            
            return ("", n)
        }
        
        static func lenEncIntArray(v:UInt64) -> [UInt8] {
      
            if v <= 250 {
                return [UInt8(v)]
            }
            else if v <= 0xffff {
                return [0xfc, UInt8(v), UInt8(v>>8)]
            }
            else if v <= 0xffffff {
                return [0xfd, UInt8(v), UInt8(v>>8), UInt8(v>>16)]
            }
            
            return [0xfe, UInt8(v), UInt8(v>>8), UInt8(v>>16), UInt8(v>>24),
                UInt8(v>>32), UInt8(v>>40), UInt8(v>>48), UInt8(v>>56)]
        }
        
        static func lenEncInt(b: [UInt8]) -> (UInt64?, Int) {
            
            if b.count == 0 {
                return (nil, 1)
            }
            
            switch b[0] {
                
                // 251: NULL
            case 0xfb:
                return (nil, 1)
                
                // 252: value of following 2
            case 0xfc:
                return (UInt64(b[1]) | UInt64(b[2])<<8, 3)
                
                // 253: value of following 3
            case 0xfd:
                return (UInt64(b[1]) | UInt64(b[2])<<8 | UInt64(b[3])<<16, 4)
                
                // 254: value of following 8
            case 0xfe:
                return (UInt64(b[1]) | UInt64(b[2])<<8 | UInt64(b[3])<<16 |
                    UInt64(b[4])<<24 | UInt64(b[5])<<32 | UInt64(b[6])<<40 |
                    UInt64(b[7])<<48 | UInt64(b[8])<<56, 9)
            default: break
            }
            
            // 0-250: value of first byte
            return (UInt64(b[0]), 1)
        }
        
        static func encPasswd(pwd:String, scramble:[UInt8]) -> [UInt8]{
            
            if pwd.characters.count == 0 {
                return [UInt8]()
            }
            
            let uintpwd = [UInt8](pwd.utf8)
            
            let s1 = Mysql_SHA1(uintpwd).calculate()
            let s2 = Mysql_SHA1(s1).calculate()
            
            var scr = scramble
            scr.appendContentsOf(s2)
            
            var s3 = Mysql_SHA1(scr).calculate()
            
            for i in 0..<s3.count {
                s3[i] ^= s1[i]
            }
            
            return s3
        }
    }
}



extension SequenceType where Generator.Element == UInt8 {
    func uInt16() -> UInt16 {
       let arr = self.map { (elem) -> UInt8 in
        return elem
        }
        return UInt16(arr[1])<<8 | UInt16(arr[0])
    }

    func int16() -> Int16 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        return Int16(arr[1])<<8 | Int16(arr[0])
    }

    
    func uInt24() -> UInt32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        return UInt32(arr[1])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }

    func int32() -> Int32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        return Int32(arr[3])<<24 | Int32(arr[2])<<16 | Int32(arr[1])<<8 | Int32(arr[0])
    }
    
    func uInt32() -> UInt32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }
    
    func uInt64() -> UInt64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var res : UInt64 = 0
        
        for i in 0..<arr.count {
            res |= UInt64(arr[i]) << UInt64(i*8)
        }
        
        return res
        
        //return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }
    
    func int64() -> Int64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var res : Int64 = 0
        
        for i in 0..<arr.count {
            res |= Int64(arr[i]) << Int64(i*8)
        }
        
        return res
        
        //return UInt32(arr[3])<<24 | UInt32(arr[2])<<16 | UInt32(arr[1])<<8 | UInt32(arr[0])
    }

    /*
    func number<Element>() -> Element  {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        let t = Element.
        
    }
*/
    
    func float32() -> Float32 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var f:Float32 = 0.0
        
        memccpy(&f, arr, 4, 4)

        return f
    }

    func float64() -> Float64 {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }
        
        var f:Float64 = 0.0
        
        memccpy(&f, arr, 8, 8)
        
        return f
    }

    func string() -> String? {
        let arr = self.map { (elem) -> UInt8 in
            return elem
        }

        guard (arr.count > 0) && (arr[arr.count-1] == 0) else {
            return ""
        }
        
        return String.fromCString(UnsafeMutablePointer<CChar>(arr))
    }
    
    static func UInt24Array(val: UInt32) -> [UInt8]{
        var buf = [UInt8](count: 3, repeatedValue: 0)
        
        buf[0] = UInt8(val)
        buf[1] = UInt8(val >> 8)
        buf[2] = UInt8(val >> 16)
        
        return buf
    }
    
    static func DoubleArray(val: Double) -> [UInt8]{
        var d = val
        var arr = [UInt8](count: 8, repeatedValue: 0)
        memccpy(&arr, &d, 8, 8)
        return arr
    }
    
    static func FloatArray(val: Float) -> [UInt8]{
        var d = val
        var arr = [UInt8](count: 4, repeatedValue: 0)
        memccpy(&arr, &d, 4, 4)
        return arr
    }
    
    static func Int32Array(val: Int) -> [UInt8]{
        var d = val
        var arr = [UInt8](count: 4, repeatedValue: 0)
        memccpy(&arr, &d, 4, 4)
        return arr
    }

    static func Int64Array(val: Int) -> [UInt8]{
        var d = val
        var arr = [UInt8](count: 8, repeatedValue: 0)
        memccpy(&arr, &d, 8, 8)
        return arr
    }

    
    static func UInt32Array(val: UInt32) -> [UInt8]{
        var buf = [UInt8](count: 4, repeatedValue: 0)
        
        let b = UInt8(val & 0xff)
        
        buf[0] = b
        buf[1] = UInt8((val >> 8) & 0xff)
        buf[2] = UInt8(val >> 16)
        buf[3] = UInt8(val >> 24)
        
        return buf
    }
    
    static func UInt16Array(val: UInt16) -> [UInt8]{
        var byteArray = [UInt8](count: 2, repeatedValue: 0)
        
        for i in 0...1 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt16((i) * 8))
        }
        
        return byteArray
    }

    
    static func IntArray(val: Int) -> [UInt8]{
        var byteArray = [UInt8](count: 4, repeatedValue: 0)
        
        for i in 0...3 {
            byteArray[i] = UInt8(0x0000FF & val >> Int((i) * 8))
        }
        
        return byteArray
    }
    
    static func UInt64Array(val: UInt64) -> [UInt8]{
        var byteArray = [UInt8](count: 8, repeatedValue: 0)
        
        for i in 0...7 {
            byteArray[i] = UInt8(0x0000FF & val >> UInt64((i) * 8))
        }
        
        return byteArray
    }

}