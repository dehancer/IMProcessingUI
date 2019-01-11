//
//  IMPScnView.swift
//  IMPRgbCubeTest
//
//  Created by Denis Svinarchuk on 11/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import SceneKit
import IMProcessing

open class IMPSCNView: IMPViewBase {

    static public let fadeIn = SCNAction.fadeOpacity(to: 1, duration: 0.05)
    static public let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: 0.15)
    static public let scaleIn = SCNAction.scale(to: 1, duration: 0.1)
    static public let scaleOut = SCNAction.scale(to: 2, duration: 0.1)
    
    static public let pulse = SCNAction.repeat(SCNAction.sequence([fadeOut, fadeIn]), count: 2)
    static public let scalePulse = SCNAction.repeat(SCNAction.sequence([scaleOut, scaleIn]), count: 2)

    public let operation:OperationQueue = {
        let o = OperationQueue()
        o.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        return o
    }()
    
    static var defaultFov:CGFloat = 35
    
    public var padding:CGFloat = 10
    public var viewPortAspect:CGFloat = 0
    
    var originalFrame:NSRect {
        let size = originalBounds.size
        let x    = (frame.size.width - size.width)/2
        let y    = (frame.size.height - size.height)/2
        return NSRect(x:x, y:y, width:size.width, height:size.height)
    }
    
    var originalBounds:NSRect {
        get{
            let w = viewPortAspect != 0 ? bounds.height * viewPortAspect : bounds.width
            let h = bounds.height
            let scaleX = w / maxCanvasSize.width
            let scaleY = h / maxCanvasSize.height
            let scale = max(scaleX, scaleY)
            return NSRect(x:0, y:0,
                          width:  w / scale,
                          height: h / scale)
        }
    }
    
    var maxCanvasSize:NSSize {
        return NSSize(width:bounds.size.width - padding,
                      height:bounds.size.height - padding)
    }
    
    public func resetView(animate:Bool = true, duration:CFTimeInterval = 0.15, complete: ((_ node:SCNNode)->Void)?=nil) {
        let node = constraintNode()
        SCNTransaction.begin()
        SCNTransaction.completionBlock = {
            complete?(node)
        }
        SCNTransaction.animationDuration = duration
        updateFov(IMPSCNView.defaultFov)
        node.pivot = SCNMatrix4Identity
        node.transform = SCNMatrix4Identity
        SCNTransaction.commit()
    }
    
    open override func layout() {
        super.layout()
        _sceneView.frame = originalFrame
    }
    
    var fov:CGFloat = defaultFov {
        didSet{
            camera.xFov = Double(fov)
            camera.yFov = Double(fov)
        }
    }
    
    lazy var camera:SCNCamera = {
        let c = SCNCamera()
        c.xFov = Double(self.fov)
        c.yFov = Double(self.fov)
        return c
    }()
    
    var lastWidthRatio: CGFloat = 0
    var lastHeightRatio: CGFloat = 0
    
    open func constraintNode() -> SCNNode {
        return SCNNode()
    }
    
    lazy var cameraNode:SCNNode = {
        let n = SCNNode()
        n.camera = self.camera
        n.camera?.automaticallyAdjustsZRange = true
        
        //initial camera setup
        n.position = SCNVector3(x: 0, y: 0, z: 3.0)
        n.eulerAngles.y = -2 * CGFloat.pi * self.lastWidthRatio
        n.eulerAngles.x = -CGFloat.pi * self.lastHeightRatio
        
        let constraint = SCNLookAtConstraint(target: self.constraintNode())
        n.constraints = [constraint]
        
        return n
    }()
    
    lazy var lightNode:SCNNode = {
        let light = SCNLight()
        light.type = SCNLight.LightType.directional
        light.castsShadow = true
        let n = SCNNode()
        n.light = light
        n.position = SCNVector3(x: 1, y: 1, z: 1)
        let constraint = SCNLookAtConstraint(target: self.constraintNode())
        n.constraints = [constraint]

        return n
    }()
    
    
    lazy var originLightNode:SCNNode = {
        let light = SCNLight()
        light.type = SCNLight.LightType.directional
        light.castsShadow = true
        let n = SCNNode()
        n.light = light
        n.light?.intensity = 1000
        n.position = SCNVector3(x: -0.5, y: 4, z: -0.5)
        return n
    }()
    
    lazy var centerLightNode:SCNNode = {
        let light = SCNLight()
        light.type = SCNLight.LightType.omni
        light.castsShadow = true
        let n = SCNNode()
        n.light = light
        n.position = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
        
        let constraint = SCNLookAtConstraint(target: self.constraintNode())
        n.constraints = [constraint]

        return n
    }()
    
    public var sceneView:SCNView {
        return _sceneView
    }
    
    lazy var _sceneView:SCNView = {
        let f = SCNView(frame: self.bounds,
                        options: ["preferredRenderingAPI" : SCNRenderingAPI.metal])
        //f.backgroundColor = NSColor.clear
        f.allowsCameraControl = false
        
        if let cam = f.pointOfView?.camera {
            cam.xFov = 0
            cam.yFov = 0
        }
        
        return f
    }()
    
    public let scene = SCNScene()
    
    open func configure(frame: CGRect){
        _sceneView.frame = originalFrame
        addSubview(_sceneView)
        _sceneView.scene = scene
        
        scene.rootNode.addChildNode(cameraNode)
        //scene.rootNode.addChildNode(centerLightNode)
        
        let pan = NSPanGestureRecognizer(target: self, action: #selector(panGesture(recognizer:)))
        pan.buttonMask = 1
        _sceneView.addGestureRecognizer(pan)
        
        let press = NSPressGestureRecognizer(target: self, action: #selector(sceneTapped(recognizer:)))
        _sceneView.addGestureRecognizer(press)
       
//        let constraint = SCNLookAtConstraint(target: self.constraintNode())

//
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light?.type = SCNLight.LightType.ambient
//        ambientLightNode.light?.color = NSColor(red:1.0, green:1.0, blue:1, alpha:1.0)
//        ambientLightNode.light?.intensity = 600
//        scene.rootNode.addChildNode(ambientLightNode)

        
//        let spotLightNode = SCNNode()
//        spotLightNode.light = SCNLight()
//        spotLightNode.light?.type = SCNLight.LightType.spot
//        spotLightNode.light?.color = NSColor(white: 1, alpha: 0)
//        spotLightNode.light?.intensity = 200
//        spotLightNode.position = SCNVector3(x: 1, y: 1, z: 1)
//        scene.rootNode.addChildNode(spotLightNode)
//        
//        spotLightNode.constraints = [constraint]

//        // Create a spotlight at the player
//        let spotLight = SCNLight()
//        spotLight.type = SCNLight.LightType.spot
//        spotLight.spotInnerAngle = 40.0
//        spotLight.spotOuterAngle = 80.0
//        spotLight.castsShadow = true
//        spotLight.color = NSColor.white
//        
//        let spotLightNode = SCNNode()
//        spotLightNode.light = spotLight
//        spotLightNode.position = SCNVector3(x: -1, y: 5.0, z: -2.0)
//        scene.rootNode.addChildNode(spotLightNode)
//        
//        // Linnk it
//       // let constraint2 = SCNLookAtConstraint(target: self)
//       // constraint2.isGimbalLockEnabled = true
//       // spotLightNode.constraints = [constraint2]
//        
//        // Create additional omni light
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = SCNLight.LightType.omni
//        lightNode.light!.color = NSColor.darkGray
//        lightNode.position = SCNVector3(x: 0, y: 10.00, z: -2)
//        scene.rootNode.addChildNode(lightNode)

        
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure(frame: self.frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure(frame: self.frame)
    }
    
    func updateFov(_ fv: CGFloat){
        if fv < 10 { fov = 10 }
        else if fv > 45 { fov = 45 }
        else { fov = fv }
    }
    
    open override func scrollWheel(with event: NSEvent) {
        //let f = fov - event.deltaY
        updateFov(fov - event.deltaY)
    }
    
    var zoomValue:CGFloat = 1
    open override func magnify(with event: NSEvent) {
        updateFov(fov - event.magnification * 10)
    }
    
    @objc func panGesture(recognizer: NSPanGestureRecognizer){
        
        let translation = recognizer.translation(in: recognizer.view!)
        
        let x = translation.x
        let y = -translation.y
        
        let anglePan = sqrt(pow(x,2)+pow(y,2))*CGFloat.pi/180.0
        
        var rotationVector = SCNVector4()
        rotationVector.x = y
        rotationVector.y = x
        rotationVector.z = 0
        rotationVector.w = anglePan
        
        constraintNode().rotation = rotationVector
        
        if(recognizer.state == .ended) {
            //
            let currentPivot = constraintNode().pivot
            let changePivot = SCNMatrix4Invert( constraintNode().transform)
            let pivot = SCNMatrix4Mult(changePivot, currentPivot)
            constraintNode().pivot = pivot
            constraintNode().transform = SCNMatrix4Identity
        }
    }
    
//    func cameraPanHandler(recognizer: NSPanGestureRecognizer) {
//        let translation = recognizer.translation(in: recognizer.view!)
//        let widthRatio = translation.x / recognizer.view!.frame.size.width + lastWidthRatio
//        let heightRatio = translation.y / recognizer.view!.frame.size.height + lastHeightRatio
//        cameraNode.eulerAngles.y =  CGFloat.pi * widthRatio
//        cameraNode.eulerAngles.x = -CGFloat.pi * heightRatio
//        
//        if (recognizer.state == .ended) {
//            lastWidthRatio = widthRatio.truncatingRemainder(dividingBy: 1)
//            lastHeightRatio = heightRatio.truncatingRemainder(dividingBy: 1)
//        }
//    }
    
    @objc func sceneTapped(recognizer: NSPressGestureRecognizer) {
        let location = recognizer.location(in: _sceneView)
        
        let hitResults = _sceneView.hitTest(location, options: nil)
        if hitResults.count > 1 {
            let result = hitResults[1] 
            let node = result.node
            
            let fadeIn = SCNAction.fadeIn(duration: 0.1)
            let fadeOut = SCNAction.fadeOut(duration: 0.1)
            let pulse = SCNAction.repeat(SCNAction.sequence([fadeOut,fadeIn]), count: 2)
            
            node.runAction(pulse)
        }
    }
}
