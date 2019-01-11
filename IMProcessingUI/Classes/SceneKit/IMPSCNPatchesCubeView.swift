//
//  IMPSCNRgbCubeView.swift
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
import IMProcessing

public class IMPSCNPatchesCubeView: IMPSCNPatchesView {
    
    public override func colorPoint(color:NSColor, radius:CGFloat, type: IMPSCNColorPoint.PointType = .sphere) -> IMPSCNColorPoint {
        return IMPSCNRgbPoint(color: color, radius: radius, type: type)
    }
    
    open override func configure(frame: CGRect){
        
        super.configure(frame: frame)
        
        scene.rootNode.addChildNode(cubeNode)
        
        for c in cornerColors {
            let n = IMPSCNRgbPoint(color: c)
            facetCornerNodes.append(n)
            _ = n.attach(to: cubeNode)
        }
        
        for f in facetColors {
            
            if let i0 = facetCornerNodes.index(where: { return $0.color == f.0 }),
                let i1 = facetCornerNodes.index(where: { return $0.color == f.1 }) {
                
                let c0 = facetCornerNodes[i0]
                let c1 = facetCornerNodes[i1]
                let line = IMPSCNLine(parent: cubeNode,
                                      v1: c0.position,
                                      v2: c1.position,
                                      color: f.0,
                                      endColor: f.1)
                cubeNode.addChildNode(line)
                
            }
        }
    }
    
    let cornerColors:[NSColor] = [
        NSColor(red: 1, green: 0, blue: 0, alpha: 1), // 0
        NSColor(red: 0, green: 1, blue: 0, alpha: 1), // 1
        NSColor(red: 0, green: 0, blue: 1, alpha: 1), // 2
        
        NSColor(red: 1, green: 1, blue: 0, alpha: 1), // 3
        NSColor(red: 0, green: 1, blue: 1, alpha: 1), // 4
        NSColor(red: 1, green: 0, blue: 1, alpha: 1), // 5
        
        NSColor(red: 1, green: 1, blue: 1, alpha: 1), // 6
        NSColor(red: 0, green: 0, blue: 0, alpha: 1), // 7
        NSColor(red: 0, green: 0, blue: 0, alpha: 1)  // 8
    ]
    
    lazy var facetColors:[(NSColor,NSColor)] = [
        (self.cornerColors[8],self.cornerColors[0]), // black -> red
        (self.cornerColors[8],self.cornerColors[1]), // black -> green
        (self.cornerColors[2],self.cornerColors[8]), // black -> blue
        
        (self.cornerColors[0],self.cornerColors[3]), // red -> yellow
        (self.cornerColors[5],self.cornerColors[0]), // red -> purple
        
        (self.cornerColors[1],self.cornerColors[3]), // green -> yellow
        (self.cornerColors[4],self.cornerColors[1]), // green -> cyan
        
        (self.cornerColors[2],self.cornerColors[4]), // blue -> cyan
        (self.cornerColors[2],self.cornerColors[5]), // blue -> purple
        
        (self.cornerColors[6],self.cornerColors[3]), // yellow -> white
        (self.cornerColors[4],self.cornerColors[6]), // purple -> white
        (self.cornerColors[5],self.cornerColors[6]), // purple -> white
        
    ]
    
    var facetCornerNodes = [IMPSCNRgbPoint]()
    
    public override func constraintNode() -> SCNNode {
        return cubeNode
    }
    
    let cubeGeometry:SCNBox = {
        let g = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        let m = SCNMaterial()
        m.diffuse.contents = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.1)
        g.materials = [m]
        
        return g
    }()
    
    lazy var cubeNode:SCNNode = {
        let c = SCNNode(geometry: self.cubeGeometry)
        c.position = SCNVector3(x: 0, y: 0, z: 0)
        return c
    }()
}
