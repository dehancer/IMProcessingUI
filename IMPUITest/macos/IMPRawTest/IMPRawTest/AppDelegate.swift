//
//  AppDelegate.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 16.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import IMProcessingUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSOpenSavePanelDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    lazy var openPanel:NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.resolvesAliases = true
        p.isExtensionHidden = false
        p.allowedFileTypes = NSImage.typeExtensions
        p.allowedFileTypes?.append(contentsOf: [
            "jpg", "JPEG", "TIFF", "TIF", "PNG", "JPG", "dng", "DNG", "CR2", "ORF"
            ])
        return p
    }()
    

    @IBAction func openFile(_ sender: NSMenuItem) {
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            if let path = openPanel.urls.first?.path {
                (NSApplication.shared.keyWindow?.contentViewController as? ViewController)?.imagePath = path
            }
        }
    }
    
    
    var type:String = "png" {
        didSet{
            var file = savePanel.nameFieldStringValue.components(separatedBy: ".")
            savePanel.nameFieldStringValue = file[0] + "."+type
        }
    }
    
    lazy var savePanel:NSSavePanel = {
        let p = NSSavePanel()
        p.delegate = self        
        p.isExtensionHidden = false
        p.allowedFileTypes = [ "png", "cube"]
        p.nameFieldLabel = "File name: "
        p.nameFieldStringValue = "curved-lut."+self.type
        p.accessoryView = self.typeSelector
        return p
    }()
    
    func panel(_ sender: Any, willExpand expanding: Bool) {
        
    }
    
    lazy var typeSelector:NSPopUpButton = {
        let b = NSPopUpButton()
        b.target = self
        b.action = #selector(typeSelectorHandler(sender:))
        b.addItems(withTitles: ["png", "cube"])
        return b
    }()
    
    @objc func typeSelectorHandler(sender:NSPopUpButton) {
        Swift.print("select \(String(describing: sender.selectedItem))")
        if let title = sender.selectedItem?.title {
            type = title
        }
    }

}


public extension NSImage {
    
    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
        unlockFocus()
    }
    
    public func resize(factor level: CGFloat) -> NSImage {
        let _image = self
        let newRect: NSRect = NSMakeRect(0, 0, _image.size.width, _image.size.height)
        
        let imageSizeH: CGFloat = _image.size.height * level
        let imageSizeW: CGFloat = _image.size.width * level
        
        let newImage = NSImage(size: NSMakeSize(imageSizeW, imageSizeH))
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.medium
        
        _image.draw(in: NSMakeRect(0, 0, imageSizeW, imageSizeH), from: newRect, operation: .sourceOver, fraction: 1)
        newImage.unlockFocus()
        
        return newImage
    }
    
    public static var typeExtensions:[String] {
        return NSImage.imageTypes.map { (name) -> String in
            return name.components(separatedBy: ".").last!
        }
    }
    
    public class func getMeta(contentsOf url: URL) -> [String: AnyObject]? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties =  CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: AnyObject] else { return nil }
        return properties
    }
    
    public class func getSize(contentsOf url: URL) -> NSSize? {
        guard let properties = NSImage.getMeta(contentsOf: url) else { return nil }
        if let w = properties[kCGImagePropertyPixelWidth as String]?.floatValue,
            let h = properties[kCGImagePropertyPixelHeight as String]?.floatValue {
            return NSSize(width: w.cgfloat, height: h.cgfloat)
        }
        return nil
    }
    
    public class func thumbNail(contentsOf url: URL, size max: Int) -> NSImage? {
        
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        
        let options = [
            kCGImageSourceShouldAllowFloat as String: true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String: false as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber,
            kCGImageSourceThumbnailMaxPixelSize as String: max as NSNumber
            ] as CFDictionary
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
        
        return NSImage(cgImage: thumbnail, size: NSSize(width: max, height: max))
    }
}

