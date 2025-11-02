//
//  NSImageExtension.swift
//  WallpaperInfoApp
//
//  Created by Brad Park on 4/13/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {

    private func imageJPGRepresentation() -> NSData? {
        if let imageTiffData = self.tiffRepresentation, let imageRep = NSBitmapImageRep(data: imageTiffData) {
            let imageProps = [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0] // Tiff/Jpeg
            // let imageProps = [NSImageInterlaced: NSNumber(value: true)] // PNG
            // let imageProps: [String: Any] = [:]
            let imageData = imageRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: imageProps) as NSData?
            return imageData
        }
        return nil
    }
    
    func rotateImage(by degrees : CGFloat) -> NSImage {
        var imageBounds = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let rotatedSize = AffineTransform(rotationByDegrees: degrees).transform(size)
        let newSize = CGSize(width: abs(rotatedSize.width), height: abs(rotatedSize.height))
        let rotatedImage = NSImage(size: newSize)

        imageBounds.origin = CGPoint(x: newSize.width / 2 - imageBounds.width / 2, y: newSize.height / 2 - imageBounds.height / 2)

        let otherTransform = NSAffineTransform()
        otherTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        otherTransform.rotate(byDegrees: degrees)
        otherTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        rotatedImage.lockFocus()
        otherTransform.concat()
        draw(in: imageBounds, from: CGRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()

        return rotatedImage
    }
    
    class func readJPGToImage(path:String) -> NSImage? {
        let image = NSImage.init(contentsOfFile: path)
        return image
        
    }
    
    func writeImageToJPG(path:String) -> Bool {
        if let imageData = self.imageJPGRepresentation() {
              imageData.write(toFile: path, atomically: false)
            return true
        }
        return false
    }
    
    func getResizedImage(_ width: Int, _ height: Int) -> NSImage {
        let destSize = NSMakeSize(CGFloat(width), CGFloat(height))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        self.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height),
                       from: NSMakeRect(0, 0, self.size.width, self.size.height),
                       operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return newImage
    }
	
    /*
    func drawText(with text:String, x:Int, y:Int, font: NSFont, color:NSColor) {
        
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let textRect = (text as NSString).size(withAttributes: fontAttributes)
        self.lockFocus()
        text.draw(in: textRect, withAttributes: textFontAttributes)
        self.unlockFocus()*/
}
