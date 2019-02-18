//
//  IMPHistogramViewMacos.swift
//  Pods
//
//  Created by denis svinarchuk on 27.07.17.
//
//

import Cocoa
import IMProcessing
//import SpriteKit
//import Surge
import simd

public protocol IMPHistogramViewDataSource {
    func histogram(view:IMPHistogramView) -> IMPHistogram
    func histogram(view:IMPHistogramView, clampEdgesForChannel index:Int) -> (left:CGFloat,right:CGFloat)
    func histogram(view:IMPHistogramView, clampColorForChannel index:Int) -> NSColor
    func histogram(view:IMPHistogramView, fillColorForChannel index:Int) -> NSColor
    func histogram(view:IMPHistogramView, strokColorForChannel index:Int) -> NSColor
    func histogram(view:IMPHistogramView, opacityForChannel index:Int) -> CGFloat
    func histogram(view:IMPHistogramView, shouldVisibleForChannel index:Int) -> Bool
}

public extension IMPHistogramViewDataSource {
    func histogram(view:IMPHistogramView, clampEdgesForChannel index:Int) -> (left:CGFloat,right:CGFloat) {
        return (0,1)
    }

    func histogram(view:IMPHistogramView, clampColorForChannel index:Int) -> NSColor {
        return NSColor.green
    }

    func histogram(view:IMPHistogramView, fillColorForChannel index:Int) -> NSColor {
        return NSColor.white
    }
    func histogram(view:IMPHistogramView, strokColorForChannel index:Int) -> NSColor {
        return NSColor.clear
    }
    func histogram(view:IMPHistogramView, opacityForChannel index:Int) -> CGFloat {
        return 0.5
    }
    func histogram(view:IMPHistogramView, shouldVisibleForChannel index:Int) -> Bool {
        return true
    }
}

#if os(OSX)
    
    
    //
    // MARK - Histogram view
    //
    public class IMPHistogramView: IMPViewBase, IMPDeferrable, CALayerDelegate {
        
        public var animated:Bool = false
        public var animationDuration:TimeInterval = 0.1

        public var backgroundColor:NSColor? {
            didSet{
                if let bc = backgroundColor {
                    wantsLayer = true
                    layer?.backgroundColor = bc.cgColor
                }
                else {
                    layer?.backgroundColor = nil
                }
            }
        }
        
        public var dataSource:IMPHistogramViewDataSource?
        
        public var obliqueLinesColor:NSColor? {
            didSet{
                reload()
            }
        }
        
        public var obliqueLinesStep:CGFloat = 6 {
            didSet{
                reload()
            }
        }
        
        public var obliqueLinesWidth:CGFloat = 0.5 {
            didSet{
                reload()
            }
        }
        
        public func reload() {
            needsDisplay = true
        }
        
        public override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            configure()
        }
        
        public required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }
        
        private func getPath(channel:[Float], index:Int, source:IMPHistogramViewDataSource) -> (CGPath,CGPath,CGPath) {
            
            let clamp = source.histogram(view: self, clampEdgesForChannel: index)
            
            let path  = CGMutablePath()
            let size  = channel.count
            let scale = bounds.width/CGFloat(size)
            
            let leftPath  = CGMutablePath()
            let rightPath = CGMutablePath()

            path.move(to: NSPoint(x:0,y:0))
            leftPath.move(to: NSPoint(x:0,y:0))
            rightPath.move(to: NSPoint(x:clamp.right*bounds.width,y:0))

            for (i,y) in channel.enumerated() {
                if y.isFinite {
                    let x = CGFloat(i) * scale
                    let p = NSPoint(x: x, y: CGFloat(y))
                    if i == 0 {
                        path.move(to: p)
                        leftPath.move(to: p)
                    }
                    else {
                        path.addLine(to: p)
                        if x<=clamp.left*bounds.width {
                            leftPath.addLine(to: p)
                        }
                        if x>=clamp.right*bounds.width {
                            rightPath.addLine(to: p)
                        }
                    }
                }
            }
            path.addLine(to: NSPoint(x:bounds.width,y:0))
            path.addLine(to: NSPoint(x:0,y:0))

            leftPath.addLine(to: NSPoint(x:clamp.left*bounds.width,y:0))
            leftPath.addLine(to: NSPoint(x:0,y:0))

            rightPath.addLine(to: NSPoint(x:bounds.width,y:0))
            rightPath.addLine(to: NSPoint(x:0,y:0))

            return (leftPath,path,rightPath)
        }
        
        public override var wantsUpdateLayer: Bool {
            return true
        }
        
        private func configure(){
            wantsLayer = true
            layer = CAShapeLayer()
            layer?.frame = bounds
            layer?.delegate = self
            layerContentsRedrawPolicy = .onSetNeedsDisplay
        }
        
        public func draw(_ layer: CALayer, in ctx: CGContext) {
            guard layer === self.layer else {return }
            drawShapes()
        }

        public override func layout() {
            super.layout()
             drawShapes()
        }
        
        private func updateShapes(newLayer:CAShapeLayer, histogram:IMPHistogram, source:IMPHistogramViewDataSource)
            ->  ([CAShapeLayer],[CAShapeLayer],[CAShapeLayer]) {
            
            var shapes:[CAShapeLayer] = [CAShapeLayer]()
            var leftClampLayers:[CAShapeLayer] = [CAShapeLayer]()
            var rightClampLayers:[CAShapeLayer] = [CAShapeLayer]()
            
            if shapes.count != histogram.channels.count {

                for i in 0..<histogram.channels.count {
                    leftClampLayers.append(CAShapeLayer())
                    leftClampLayers[i].masksToBounds = true

                    rightClampLayers.append(CAShapeLayer())
                    rightClampLayers[i].masksToBounds = true
                    
                    shapes.append(CAShapeLayer())
                    shapes[i].backgroundColor = NSColor.clear.cgColor
                    
                    shapes[i].addSublayer(leftClampLayers[i])
                    shapes[i].addSublayer(rightClampLayers[i])
                    newLayer.addSublayer(shapes[i])
                }
            }
            
            for (i,s) in shapes.enumerated() {
                s.frame = bounds
                rightClampLayers[i].frame = bounds
                leftClampLayers[i].frame = bounds
            }
            return (shapes,leftClampLayers,rightClampLayers)
        }
        
        private var oldLayer:CAShapeLayer?
        
        private func drawShapes() {
            
            var newLayer = CAShapeLayer()
            
            newLayer.frame = bounds
            
            guard let source = dataSource else { return }
            let histogram = source.histogram(view: self)
            
             var (shapes,leftClampLayers,rightClampLayers)
                = updateShapes(newLayer: newLayer, histogram: histogram, source: source)
            
            for (i,c) in histogram.pdf(scale: bounds.height.float).channels.enumerated() {

                let s = shapes[i]

                if !source.histogram(view: self, shouldVisibleForChannel: i) {
                    s.isHidden = true
                }
                else {
                    s.isHidden = false
                }
                
                let (left,path,right) = getPath(channel: c, index: i, source: source);
                
                s.path = path
                s.strokeColor = source.histogram(view: self, strokColorForChannel: i).cgColor
                s.fillColor   = source.histogram(view: self, fillColorForChannel: i).cgColor
                s.opacity     = source.histogram(view: self, opacityForChannel: i).float
                s.fillRule = CAShapeLayerFillRule.evenOdd
                

                var sh = CAShapeLayer()
                sh.path = left
                sh.fillRule = CAShapeLayerFillRule.evenOdd
                
                let color = source.histogram(view: self, clampColorForChannel: i)
                
                let strokeColor = obliqueLinesColor ?? NSColor.black
                let image = NSImage(size: NSSize(width: bounds.width, height: bounds.height))
                image.drawObliqueLines(color: color,
                                       linesColor: strokeColor,
                                       lineWidth: obliqueLinesWidth,
                                       step: obliqueLinesStep)

                let oblique = NSColor(patternImage: image).cgColor

                leftClampLayers[i].backgroundColor = oblique

                leftClampLayers[i].mask = sh

                sh = CAShapeLayer()
                sh.path = right
                sh.fillRule = CAShapeLayerFillRule.evenOdd
                
                rightClampLayers[i].backgroundColor = oblique
                
                rightClampLayers[i].mask = sh
            }
            
            if animated {
                if let old = oldLayer {
                    oldLayers.append(old)
                    for s in old.sublayers! {
                        s.add(self.animationFade, forKey: "fade")
                    }
                }
            }
            
            layer?.addSublayer(newLayer)
            
            if !animated {
                oldLayer?.removeFromSuperlayer()
            }
            
            if animated {
                for s in newLayer.sublayers! {
                    s.add(self.animationAppear, forKey: "appear")
                }
            }
            
            oldLayer = newLayer
        }
        
        lazy var animationFade:CABasicAnimation = {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.delegate = self
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.isRemovedOnCompletion = true
            return animation
        }()
        
        lazy var animationAppear:CABasicAnimation = {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.delegate = self
            animation.fromValue = 0.0
            animation.toValue = 1.0
            animation.duration = animationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.isRemovedOnCompletion = true
            return animation
        }()
        
        
        private var oldLayers:[CAShapeLayer] = []
    }

extension IMPHistogramView:CAAnimationDelegate{
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool){
        for o in oldLayers {
            o.removeFromSuperlayer()
        }
        oldLayers.removeAll()
    }
}

    extension NSImage {
        func drawObliqueLines(color:NSColor, linesColor:NSColor, lineWidth:CGFloat, step:CGFloat) {
            
            var x:CGFloat = -size.width
            
            let lines = Int(ceil(size.width/step))*2
            
            let paths = NSBezierPath()
            
            for _ in 0..<lines {
                let path = NSBezierPath()
                path.move(to: NSPoint(x: x, y: size.height))
                path.line(to: NSPoint(x: x+size.width, y: 0))
                x += step
                paths.append(path)
            }

            lockFocus()
            
            color.setFill()
            NSBezierPath.fill(NSRect(x: 0, y: 0, width: size.width, height: size.height))
            
            linesColor.setStroke()
            paths.lineWidth = lineWidth
            paths.stroke()
            
            unlockFocus()
        }
    }
    
#endif
