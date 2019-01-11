//
//  IMPSCNPatchesView.swift
//  Pods
//
//  Created by denis svinarchuk on 13.04.17.
//
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import SceneKit
import IMProcessing

open class IMPSCNPatchesView: IMPSCNView {
    
    public func colorPoint(color:NSColor, radius:CGFloat, type: IMPSCNColorPoint.PointType = .sphere) -> IMPSCNColorPoint {
        return IMPSCNRgbPoint(color: color, radius: radius, type: type)
    }
    
    public var lineNodes = [IMPSCNLine]()
    public var sourceNodes = [IMPSCNColorPoint]()
    public var targetNodes = [IMPSCNColorPoint]()
    
    func patchRunAction(at index:Int, action:SCNAction) {
        DispatchQueue.main.async {
            guard index < self.targetNodes.count && index >= 0 else { return }
            guard index < self.lineNodes.count && index >= 0 else { return }
            guard index < self.sourceNodes.count && index >= 0 else { return }
            
            let l = self.lineNodes[index]
            let s = self.sourceNodes[index]
            let t = self.targetNodes[index]
            
            let la = SCNAction.run {_ in
                l.runAction(action)
            }
            let sa = SCNAction.run {_ in
                s.runAction(action)
            }
            let ta = SCNAction.run {_ in
                t.runAction(action)
            }
            let g = SCNAction.group([la,sa,ta])
            
            t.runAction(g)   
        }
    }
    
    public func scaleInPatch(at index:Int)  {
        patchRunAction(at: index, action: IMPSCNPatchesCylinderView.scaleIn)
    }

    public func scaleOutPatch(at index:Int)  {
        patchRunAction(at: index, action: IMPSCNPatchesCylinderView.scaleOut)
    }

    public func highlightPatch(at index:Int)  {
        patchRunAction(at: index, action: IMPSCNPatchesCylinderView.pulse)
    }
    
    public var grid:(sources:[float3], targets:[float3]) = ([],[]) {
        didSet{
            if !isHidden {
                self.updateNodes()
            }
        }
    }
    
    open override var isHidden: Bool {
        didSet{
            if oldValue == true && oldValue != isHidden {
                updateNodes()
            }
        }
    }
    
    private func updateNodes(){
        var isNew = false
        
        if targetNodes.count != grid.targets.count ||
            sourceNodes.count != grid.targets.count ||
            lineNodes.count != grid.targets.count {
            
            isNew = true
            
            for n in targetNodes { n.removeFromParentNode() }
            targetNodes = [IMPSCNColorPoint]()
            
            for n in sourceNodes { n.removeFromParentNode() }
            sourceNodes = [IMPSCNColorPoint]()
            
            for n in lineNodes { n.removeFromParentNode() }
            lineNodes   = [IMPSCNLine]()
            
        }
        
        if !isNew {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.2
        }
        
        for i in 0..<grid.targets.count {
            let color = grid.targets[i]
            if isNew {
                let n = colorPoint(color: NSColor(rgb: color), radius: 0.02)
                targetNodes.append(n.attach(to: constraintNode()) as! IMPSCNColorPoint)
            }
            else {
                targetNodes[i].color = NSColor(rgb: color)
            }
        }
        
        for index in 0..<grid.targets.count {
            
            let p = grid.sources[index]
            let t = grid.targets[index]
            let color = NSColor(rgba: float4(p.r,p.g,p.b,1))
            
            let n = colorPoint(color: color, radius: 0.005 )
            let tn = targetNodes[index]
            
            if isNew {
                sourceNodes.append(n.attach(to: constraintNode()) as! IMPSCNColorPoint)
                
                let line = IMPSCNLine(parent: constraintNode(),
                                      v1: n.position,
                                      v2: tn.position,
                                      color: color,
                                      endColor: NSColor(rgb: t))
                
                constraintNode().addChildNode(line)
                
                lineNodes.append(line)
            }
            else {
                lineNodes[index].colors = [color,NSColor(rgb: t)]
                lineNodes[index].v1 = n.position
                lineNodes[index].v2 = tn.position
                sourceNodes[index].color = color
            }
        }
        
        if !isNew {
            SCNTransaction.commit()
        }
    }
}
