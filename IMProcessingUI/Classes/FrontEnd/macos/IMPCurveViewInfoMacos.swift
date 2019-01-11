//
//  IMPCurveInfo.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 16.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import IMProcessing
import simd

#if os(OSX)
    
    public class IMPCurveViewInfo: Equatable, IMPDeferrable{
        
        public static func == (lhs: IMPCurveViewInfo, rhs: IMPCurveViewInfo) -> Bool {
            return lhs.id == rhs.id
        }
        
        public var index:Int { return _index }
        public var id:String { return _id }
        public let name:String
        public let title:String
        public let color:NSColor
        public let clampColor:NSColor
        public var controlPoints:[float2] {
            guard let s = curve else { return [] }
            return s.controlPoints
        }
        
        public var isActive = false {
            didSet {
                guard oldValue != isActive else { return }
                guard let v = view else {return}
                v.needsDisplay = true
                if isActive {
                    v.delegate?.curvesView(v, didSelect: self)
                }
                else {
                    v.delegate?.curvesView(v, didDeselect: self)
                }
            }
        }
        
        public var isHover = false {
            didSet {
                guard oldValue != isHover else { return }
                guard let v = view else {return}
                v.needsDisplay = true
            }
        }
        
        public var _id:String
        public init (id: String, name: String, title: String, color: NSColor, clampColor: NSColor, curve:IMPCurve) {
            self._id = id
            self.name = name
            self.title = title
            self.color = color
            self.clampColor = clampColor
            defer {
                self.curve = curve
            }
        }
        
        public convenience init (name: String, color: NSColor, clampColor: NSColor) {
            let s = name.index(name.startIndex, offsetBy: 0)
            let e = name.index(name.startIndex, offsetBy: 1) 
            self.init(id: name, 
                      name: name, 
                      title:String(name[s..<e]), 
                      color: color, 
                      clampColor: clampColor, 
                      curve:IMPCurve(interpolator: IMPCubicSpline(resolution: kIMPCurveCollectionResolution),
                                     type: .interpolated,
                                     edges: ([float2(-10000)],[float2(10000)])))
        }
    
        public convenience init (name: String, title:String, color: NSColor, clampColor: NSColor) {
            self.init(id: name, 
                      name: name, 
                      title:title, 
                      color: color, 
                      clampColor: clampColor, 
                      curve:IMPCurve(interpolator: IMPCubicSpline(resolution: kIMPCurveCollectionResolution),
                                     type: .interpolated,
                                     edges: ([float2(-10000)],[float2(10000)])))
        }
        
        public var curve:IMPCurve? {
            didSet {
                guard let c = curve else { return }
                c.precision = view?.precision.float ?? IMPCurvesView.defaultPrecision.float
                c.bounds = (float2(0),float2(1))
                if c.controlPoints.count<2{
                    c.add(points: [c.bounds.left,c.bounds.right])
                }
                c.addUpdateObserver(observer: { (curve) in
                    guard let v = self.view  else { return }
                    self.deferrable.block = {
                        v.delegate?.curvesView(v, didUpdate: self)                            
                    }
                })
            }
        }
        
        internal var _index:Int = 0
        internal var view:IMPCurvesView?
    }
    
    public extension IMPCurveViewInfo {
        
        public static func rgb() -> [IMPCurveViewInfo] { return [
            IMPCurveViewInfo(name: IMPColorSpace.rgb.rawValue, title: "Master",   color:  NSColor(red: 1,   green: 1, blue: 1, alpha: 0.8), clampColor: NSColor(red: 1, green: 0.4, blue: 0, alpha: 0.8)),
            IMPCurveViewInfo(name: IMPColorSpace.rgb.channelDescription[0], title:IMPColorSpace.rgb.channelNames[0],   color:  NSColor(red: 1,   green: 0, blue: 0, alpha: 0.95), clampColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.8)),
            IMPCurveViewInfo(name: IMPColorSpace.rgb.channelDescription[1], title:IMPColorSpace.rgb.channelNames[1],   color:  NSColor(red: 0,   green: 1, blue: 0.2, alpha: 0.95), clampColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.8)),
            IMPCurveViewInfo(name: IMPColorSpace.rgb.channelDescription[2], title:IMPColorSpace.rgb.channelNames[2],   color:  NSColor(red: 0,   green: 0.2, blue: 1, alpha: 0.95), clampColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.8))
            ]
        }
        
        public static func lab() -> [IMPCurveViewInfo] { return [
            IMPCurveViewInfo(name: IMPColorSpace.lab.channelDescription[0], title:IMPColorSpace.lab.channelNames[0],   color:  NSColor(red: 1,   green: 1, blue: 1, alpha: 0.95), clampColor: NSColor(red: 1, green: 0.4, blue: 0, alpha: 0.8)),
            IMPCurveViewInfo(name: IMPColorSpace.lab.channelDescription[1], title:IMPColorSpace.lab.channelNames[1],   color:  NSColor(red: 1,   green: 0.2, blue: 0, alpha: 0.95), clampColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.8)),
            IMPCurveViewInfo(name: IMPColorSpace.lab.channelDescription[2], title:IMPColorSpace.lab.channelNames[2],   color:  NSColor(red: 0,   green: 0.2, blue: 1, alpha: 0.95), clampColor: NSColor(red: 1, green: 1, blue: 1, alpha: 0.8))
            ]
        }
    }
    
#endif

