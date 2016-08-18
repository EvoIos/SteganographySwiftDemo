//
//  ViewController.swift
//  SteganographySwiftDemo
//
//  Created by zhenglanchun on 16/8/18.
//  Copyright © 2016年 LC. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var bottomImgView: UIImageView!
    
    var positions: [(Int, Int)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imgView.image = UIImage(named: "xiaolan.png")
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let img = UIImage(named: "qushui.png")!
            let willBeWritenImg = UIImage(named: "xiaolan.png")
            //读取坐标点
            if let context = self.getContext(img) {
                self.positions = self.getKeyPositionsWithImage(img, inputContext: context)
            }
            //写入到目标图片
            if let context = self.getContext(willBeWritenImg!) {
                //写入image
                let newImage = self.encodeSteganographyWithImage(willBeWritenImg!, context: context, position: self.positions!)
                dispatch_async(dispatch_get_main_queue(), {
                    self.bottomImgView.image = newImage
                })
            }
            
            print(self.positions!)
        }
    }
    
    @IBAction func decode(sender: AnyObject) {
        //上面的视图解码
        if let image = imgView.image {
            
            guard let context = getContext(image) else {
                print("获取不到context！")
                return
            }

            let decodeImg = decodeImage(image, context: context)
            imgView.image = decodeImg
        }
        
        //下面的视图解码
        if let image = bottomImgView.image {
            guard let context = getContext(image) else {
                print("获取不到context！")
                return
            }
            if positions != nil {
                let decodeImg = decodeImage(image, context: context)
                bottomImgView.image = decodeImg
            }
        }
    }
    
    //MARK: -
    func getContext(inputImage: UIImage) -> CGContext? {
        let inputCGImage = inputImage.CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = CGImageGetWidth(inputCGImage)
        let height = CGImageGetHeight(inputCGImage)
        let bytesPerPixel = 4
        let bitsPerComponent = 8
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = RGBA32.bitmapInfo
        
        guard let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo) else {
                print("unable to create context")
                return nil
        }
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: CGFloat(width),height: CGFloat(height)), inputCGImage)
        
        return context
    }
    
    //MARK: 解码 - 取red字段最低位，1 隐藏的信息， 0 无用的信息
    func decodeImage(inputImage: UIImage, context: CGContext) -> UIImage {
        
        let pixelBuffer = UnsafeMutablePointer<RGBA32>(CGBitmapContextGetData(context))
        var currentPixel = pixelBuffer
        
        for _ in 0..<imageHeight(inputImage) {
            for _ in 0..<imageHeight(inputImage) {
                //获取当前指针指向的值
                let orgin = currentPixel.memory
                //用0b0000 0001 与操作，获取最低位值
                let flag = orgin.red & 0b00000001
                //设定red值
                var redValue:UInt8 = 0
                if  flag == 1 {
                    redValue = 255
                }
                
                let newColor = RGBA32(red: redValue, green: 0, blue: 0, alpha: orgin.alpha)
                currentPixel.memory = newColor
                currentPixel += 1
            }
        }
        //输出image
        let outputCGImage = CGBitmapContextCreateImage(context)
        let outputImage = UIImage(CGImage: outputCGImage!, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        return outputImage
    }
    
    //MARK: 编码，写入图像
    func encodeSteganographyWithImage(inputImage: UIImage, context: CGContext, position: [(Int,Int)] ) -> UIImage {
        
        let pixelBuffer = UnsafeMutablePointer<RGBA32>(CGBitmapContextGetData(context))
        var currentPixel = pixelBuffer
        
        var index = 0
        for height in 0..<imageHeight(inputImage) {
            for width in 0..<imageHeight(inputImage) {
                
                let originColor = currentPixel.memory
                var newRewValue:UInt8 = originColor.red
                
                if positions != nil && index < positions?.count {
                    if (width,height) == positions![index] {
                        index += 1
                        newRewValue = setLastBitOne(originColor.red)
                    } else {
                        newRewValue = setLastBitZero(originColor.red)
                    }
                }
                
                currentPixel.memory = RGBA32(red: newRewValue, green: originColor.green, blue: originColor.blue, alpha: originColor.alpha)
                
                currentPixel += 1
            }
        }
        
        let outputCGImage = CGBitmapContextCreateImage(context)
        let outputImage = UIImage(CGImage: outputCGImage!, scale: inputImage.scale, orientation: inputImage.imageOrientation)
        return outputImage
        
    }
    
    //MARK: 获取关键点像素坐标， 目标图像 - 白底黑字
    func getKeyPositionsWithImage(inputImage: UIImage, inputContext: CGContext) -> [(Int, Int)] {
        
        let pixelBuffer = UnsafeMutablePointer<RGBA32>(CGBitmapContextGetData(inputContext))
        var currentPixel = pixelBuffer
        
        var result: [(Int, Int)] = [(0,0)]
        for i in 0..<imageHeight(inputImage) {
            for j in 0..<imageHeight(inputImage) {
                //获取黑字像素的坐标
                let black = RGBA32(red: 0, green: 0, blue: 0, alpha: 255)
                if  currentPixel.memory == black {
                    result.append((j,i))
                }
                currentPixel += 1
            }
        }
        return result
    }

    
    //MARK: - helper
    func imageWidth(inputImage: UIImage) -> Int {
        return CGImageGetWidth(inputImage.CGImage)
    }
    
    func imageHeight(inputImage: UIImage) -> Int {
        return CGImageGetHeight(inputImage.CGImage)
    }
    
    func setLastBitZero(red: UInt8) -> UInt8 {
        let flag = red & 0b00000001
        if flag == 0 {
            return red
        } else {
            return red - 1
        }
    }
    
    func setLastBitOne(red: UInt8) -> UInt8 {
        let flag = red & 0b00000001
        if flag == 0 {
            return red + 1
        } else {
            return red
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

