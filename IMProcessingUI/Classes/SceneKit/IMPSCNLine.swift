//
//  IMPSCNLine.swift
//  IMPRgbCubeTest
//
//  Created by Denis Svinarchuk on 12/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import SceneKit

private extension SCNVector3{
    func distance( _ receiver:SCNVector3) -> Float{
        let xd = receiver.x - self.x
        let yd = receiver.y - self.y
        let zd = receiver.z - self.z
        let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
        
        if (distance < 0){
            return (distance * -1)
        } else {
            return (distance)
        }
    }
}

//
// sources: http://stackoverflow.com/questions/35002232/draw-scenekit-object-between-two-points
//
public class   IMPSCNLine: SCNNode {
    
    public var v1 = SCNVector3() { didSet { configure() } }
    
    public var v2 = SCNVector3() { didSet { configure() } }

    public var colors:[NSColor] = [NSColor]() { didSet{ configure() } }
    
    public var radius:CGFloat = 0.005 { didSet{ configure() } }
    
    public var radialSegmentCount:Int = 46 { didSet{ configure() } }
        
    private func configure() {
        
        height = v1.distance(v2)
        
        position = v1
        
        nodeV2.position = v2
        
        zAlign.eulerAngles.x = CGFloat.pi/2
        
        cyl = SCNCylinder(radius: radius, height: CGFloat(height))
        cyl?.radialSegmentCount = radialSegmentCount
        
        if colors.count>1 {
            let grad = NSGradient(colors: colors)
            let rect = NSRect(x:0,y:0,width: 100, height: 10)
            let image = NSImage(size: rect.size)
            let path = NSBezierPath(rect: rect)
            image.lockFocus()
            grad?.draw(in: path, angle: 270)
            image.unlockFocus()
            
            cyl?.firstMaterial?.diffuse.contents = image
        }
        else {
            cyl?.firstMaterial?.diffuse.contents =  colors.count == 1 ? colors[0] : NSColor.white
        }
        
        cyl?.firstMaterial?.diffuse.magnificationFilter = .none
        cyl?.firstMaterial?.diffuse.wrapS = .clamp
        cyl?.firstMaterial?.diffuse.wrapT = .clamp
        cyl?.firstMaterial?.diffuse.intensity = 2.0
        
        nodeCyl.geometry = cyl
        
        nodeCyl.position.y = CGFloat(-1 * height / Float(2))
    }
    
    private let nodeCyl = SCNNode()
    private var cyl:SCNCylinder?
    private var height:Float!
    private let nodeV2 = SCNNode()
    private let zAlign = SCNNode()

    public init(
        parent: SCNNode,      //Needed to add destination point of your line
        v1: SCNVector3,       //source
        v2: SCNVector3,       //destination
        color: NSColor,
        endColor: NSColor? = nil,
        radius: CGFloat = 0.001,
        radialSegmentCount: Int = 48
        )
    {
        super.init()
     
        parent.addChildNode(nodeV2)
        zAlign.addChildNode(nodeCyl)

        colors.append(color)
        
        if let c = endColor { colors.append(c) }
        else { colors.append(color)  }

        self.v1 = v1
        self.v2 = v2

        addChildNode(zAlign)
        constraints = [SCNLookAtConstraint(target: nodeV2)]

        configure()
    }
    
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
