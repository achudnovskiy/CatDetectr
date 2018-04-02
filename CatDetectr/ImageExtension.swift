//
//  ImageExtension.swift
//  CatDetectr
//
//  Created by Sophos on 2018-03-26.
//  Copyright © 2018 Sophos. All rights reserved.
//

import Cocoa

extension NSImage {
    
    /// The height of the image.
    var height: CGFloat {
        return size.height
    }
    
    /// The width of the image.
    var width: CGFloat {
        return size.width
    }
    
    // MARK: Resizing
    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
    func resize(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })
        
        return image
    }
    
    /// Copy the image and resize it to the supplied size, while maintaining it's
    /// original aspect ratio.
    ///
    /// - Parameter size: The target size of the image.
    /// - Returns: The resized image.
    func resizeMaintainingAspectRatio(withSize targetSize: NSSize) -> NSImage? {
        let newSize: NSSize
        let widthRatio  = targetSize.width / self.width
        let heightRatio = targetSize.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio),
                             height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio),
                             height: floor(self.height * heightRatio))
        }
        return self.resize(withSize: newSize)
    }
    
    // MARK: Cropping
    /// Resize the image, to nearly fit the supplied cropping size
    /// and return a cropped copy the image.
    ///
    /// - Parameter size: The size of the new image.
    /// - Returns: The cropped image.
    func crop(toSize targetSize: NSSize) -> NSImage? {
        guard let resizedImage = self.resizeMaintainingAspectRatio(withSize: targetSize) else {
            return nil
        }
        let x     = floor((resizedImage.width - targetSize.width) / 2)
        let y     = floor((resizedImage.height - targetSize.height) / 2)
        let frame = NSRect(x: x, y: y, width: targetSize.width, height: targetSize.height)
        
        guard let representation = resizedImage.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        let image = NSImage(size: targetSize,
                            flipped: false,
                            drawingHandler: { (destinationRect: NSRect) -> Bool in
                                return representation.draw(in: destinationRect)
        })
        
        return image
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {return nil}
        
        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return resultPixelBuffer
    }

}
