//
//  IMPCurveView.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 16.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import simd

#if os(OSX)


//
// MARK - Curve view
//
public class IMPCurvesView: IMPViewBase, IMPDeferrable {
    
    public enum MarkerType {
        case rect
        case arc
    }
    
    public override var needsDisplay: Bool {
        set{
            DispatchQueue.main.async {
                super.needsDisplay = newValue
            }
        }
        get{
            return super.needsDisplay
        }
    }
    
    public var padding:(dX:CGFloat,dY:CGFloat) = (10,10) {didSet{ needsDisplay = true }}
    
    public var delegate:IMPCurvesViewDelegate?
    
    public var gridDimension:(Int,Int) = (10,10) {didSet{ needsDisplay = true }}
    public var gridAxisGradient:(start:CGFloat,end:CGFloat) = (0.9,0.2) 
    public var gridColor               = NSColor(red:   1, 
                                                 green: 1, 
                                                 blue:  1, 
                                                 alpha: 0.2) { didSet{ needsDisplay = true } }

    public var gridBoldColor           = NSColor(red:   0.8, 
                                                 green: 0.8, 
                                                 blue:  0.8, 
                                                 alpha: 0.2) { didSet{ needsDisplay = true } }

    
    public var gridWidth:CGFloat       = 1 { didSet{ needsDisplay = true } }
    public var gridAxisWidth:CGFloat   = 3 { didSet{ needsDisplay = true } }

    public var isSelectable  = true

    public var markerFillColor           = NSColor.clear { didSet{ needsDisplay = true } }
    public var markerSize:CGFloat        = 10 { didSet{ needsDisplay = true } }
    public var markerType:MarkerType     = .arc { didSet{ needsDisplay = true } }
    public var markerRadius:CGFloat     { return markerSize/2 }
    public var edgeMarkerType:MarkerType = .rect { didSet{ needsDisplay = true } }

    public var lineWidth:CGFloat = 1 { didSet{ needsDisplay = true } }
    public var activeLineScale:CGFloat = 1.5 { didSet{ needsDisplay = true } }
    public var nonActiveLineAlpha:CGFloat = 0.3 { didSet{ needsDisplay = true } }
    
    public static var defaultPrecision:CGFloat = 0.025
    
    public var precision = defaultPrecision
    {
        didSet{
            updatePrec()
            needsDisplay = true
        }
    }

    private var screenScale = NSScreen.main?.backingScaleFactor ?? 1.0
    private func updatePrec(){
        for l in list {
            l.curve?.precision = Float(precision) //Float(precision/min(frame.width, frame.height) * screenScale)
        }        
    }
    
    public var info:[IMPCurveViewInfo] {
        set {
            list.removeAll()
            for (index,i) in newValue.enumerated() {
                self[i.id] = i
                i._index = index
                // delegate?.curvesView(self, didAdd: i, points: i.controlPoints)
            }
            needsDisplay = true
        }
        get {
            return list 
        }
    }
    
    fileprivate var list = [IMPCurveViewInfo]()
    
    public func reset() {
        for l in self.list {
            guard let curve = l.curve else { continue }
            curve.reset()
            curve.bounds.left = curve.controlPoints[0]
            curve.bounds.right = curve.controlPoints[1]
        }
        for l in self.list {
            self.delegate?.curvesView(self, didRemove: l, points: l.controlPoints)
        }
        needsDisplay  = true   
        
    }
    
    private subscript(id:String) -> IMPCurveViewInfo? {
        get{
            let el = list.filter { (object) -> Bool in
                return object.id == id
            }
            if el.count > 0 {
                return el[0]
            }
            else {
                return nil
            }
        }
        set{
            if let index = (list.firstIndex { (object) -> Bool in
                return object.id == id
            }) {
                if let v = newValue {
                    v.view = self
                    list[index] = v
                }
            }
            else {
                if let v = newValue {
                    v._id = id
                    v.view = self
                    list.append(v)
                }
                else {
                    let el = list.filter { (object) -> Bool in
                        return object.id == id
                    }
                    if el.count > 0 {
                        list.removeObject(object: el[0])
                    }
                }
            }
        }
    }
    
    fileprivate var activeCurve:IMPCurveViewInfo? = nil
   
    private func convertPoint(event:NSEvent) -> float2 {
        let location = event.locationInWindow
        let point  = self.convert(location,from:nil)
        let rect = NSInsetRect(bounds, padding.dX, padding.dY)
        var xy = (float2(point.x.float,point.y.float) - float2(padding.dX.float, padding.dY.float)) / float2(rect.width.float,rect.height.float)
        xy.y -= (Float(markerSize/2) - Float(lineWidth/2))/rect.height.float
        xy.x -= Float(lineWidth/2)/rect.height.float
        return xy
    }
    
    fileprivate var currentPoint:float2?
    private var currentPointIndex:Int?                
    
    private func dragged(with event: NSEvent){
        
        guard let curve = activeCurve?.curve else { return }
        guard let index = currentPointIndex else { return }

        var xy = convertPoint(event: event)
        
        if curve.type != .smooth  && curve.controlPoints.count > 1 {
            if index == 0 {
                let nextp = curve.controlPoints[index+1]
                if nextp.x-xy.x <= curve.closeDistance {
                    xy.x = curve.controlPoints[index].x
                }
            }
            if index == curve.controlPoints.count-1 {
                let nextp = curve.controlPoints[index-1]
                if xy.x - nextp.x <= curve.closeDistance {
                    xy.x = curve.controlPoints[index].x
                }
            }
        }
        
        if let p  = curve.set(point: xy, at: index) {
            currentPoint = p
            currentPointIndex = index
            
            guard curve.type == .interpolated else {  return }
            
            if index == 0 {
                curve.bounds.left = p
                needsDisplay = true
                return
            }
            
            if index == curve.controlPoints.count-1 {
                curve.bounds.right = p
                needsDisplay = true
                return
            }
            
            let v = curve.closeToCurve(point: p)
            
            func didRemove(_ removed: Bool) {
                if removed {
                    self.currentPoint = nil
                    self.currentPointIndex = nil
                    self.delegate?.curvesView(self, didRemove: self.activeCurve!, points: [p])
                }
            }
            
            if v == nil {
                curve.remove(points: [p]) { (removed) in
                    didRemove(removed)
                }
            }
            else {
                for p in curve.controlPoints {
                    let v = curve.closeToCurve(point: p)
                    
                    if v == nil {
                        curve.remove(points: [p]) { (removed) in
                            didRemove(removed)
                        }
                    }
                }
            }
        }
        needsDisplay = true
    }
    
    override public func mouseDragged(with event: NSEvent) {
        self.dragged(with: event)
    }
    
    private func closeToCurveOrPoint(info:IMPCurveViewInfo, xy:float2) -> Bool {
        var p = info.curve?.closeToCurve(point: xy)
        if p == nil {
            if info.curve?.indexOf(point: xy) != nil {
                p = xy
            }
        }
        if p == nil {
            return false
        }
        
        return true
    }
    
    public func setActive(_ index:Int) {
        for (k,i) in info.enumerated() {
            i.isHover = false
            i.isActive = false
            if index == k {
                i.isActive = true
                activeCurve = i
            }
        }
    }
    
    public override func mouseUp(with event: NSEvent) {        
        if let info = activeCurve {
            delegate?.curvesView(self, didEndUpdate: info)
        }
        
    }
    
    private var currentCursor:NSCursor?
    override public func mouseDown(with event: NSEvent) {
                
        let xy = convertPoint(event: event)
        
        currentPointIndex = nil
        currentPoint = nil
        
        if activeCurve == nil || event.clickCount == 2 {
            
            if let i = currentClosestCurve {
                if closeToCurveOrPoint(info: i, xy: xy) {
                    for ii in info {
                        ii.isHover = false
                        if isSelectable {
                            ii.isActive = false
                        }
                    }
                    if isSelectable {
                        i.isActive = true
                        activeCurve = i
                    }
                    currentPoint = xy
                }
                else if isSelectable {                    
                    i.isActive = false
                    activeCurve = nil
                }
            }
        }
        else {
            var has = false
            for i in info {
                if closeToCurveOrPoint(info: i, xy: xy) {
                    currentPoint = xy
                    has = true
                }
            }
            if !has {
                for i in info {
                    i.isHover = false
                    if isSelectable {
                        i.isActive = false
                    }
                }
                if isSelectable {
                    activeCurve = nil
                }
                return
            }
        }
        
        
        if let info = activeCurve, let curve = info.curve {
         
            
            curve.addCloseTo(xy) { (isNew, point, index) in

                self.currentPointIndex = index
                self.currentPoint = point
                
                if index == 0 || index == curve.controlPoints.count-1 {
                    return
                }
                
                if event.clickCount == 2 {
                    
                    if let p = point {
                        curve.remove(points: [p]) { (isRemoved) in
                            if isRemoved {
                                self.delegate?.curvesView(self, didRemove: info, points: [p])
                            }
                        }
                    }
                }
                else if let p = point {
                    guard isNew else { return }
                    self.delegate?.curvesView(self, didAdd: info, points: [p])
                }
            }
        }
    }
    
    private var currentClosestCurve:IMPCurveViewInfo?
    
    private func cursor(info:IMPCurveViewInfo) -> NSCursor {
        let width = markerSize*screenScale*1.5
        let size = NSSize(width: width, height: width) //NSCursor.crosshair.image.size
        let image = NSImage(symbol: "+", color: info.color, size: size) 
        let cursor = NSCursor(image: image, hotSpot: NSPoint(x: size.width/2, y: size.height/2))
        return cursor
    }    
    
    public override func mouseMoved(with event: NSEvent) {
                
        let xy = convertPoint(event: event)
        
        var closestCurve:IMPCurveViewInfo? = nil
        var minDist = Float(precision) ///min(bounds.width,bounds.height)*screenScale)
        
        for i in info {
            guard let curve = i.curve else { continue }
            let cp = curve.closestPointOfCurve(to: xy)
            let dist = distance(cp, xy)
            
            if dist < minDist {
                minDist = dist
                closestCurve = i
                break
            }
        }
        
        currentClosestCurve = closestCurve        
        
        if isSelectable {
            guard activeCurve == nil else {
                if closestCurve == nil || closestCurve != activeCurve {
                    currentCursor?.set()
                }
                else if let inf = closestCurve {
                    cursor(info: inf).set()
                }        
                return             
            }        
        }
        
        if closestCurve == nil {
            currentCursor?.set()
        }
        else if let inf = closestCurve {
            if activeCurve != nil && closestCurve != activeCurve {
                currentCursor?.set()
            }
            else {
                cursor(info: inf).set()
            }
        }            

        if let i = closestCurve {
            let p = i.curve?.closeToCurve(point: xy)
            if p != nil {
                
                let isnt = i.isHover
                
                for ii in info {
                    ii.isHover = false
                }
                i.isHover = true
                if !isnt {
                    delegate?.curvesView(self, didHighlight: i)
                }
                return
            }
        }
        for ii in info {
            ii.isHover = false
        }
    }
    
    private lazy var trackingArea:NSTrackingArea? = nil
    
    override public func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingArea{
            removeTrackingArea(t)
        }
        trackingArea = NSTrackingArea(rect: NSZeroRect,
                                      options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .cursorUpdate, .activeAlways],
                                      owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    public override func cursorUpdate(with event: NSEvent) {     
        currentCursor = NSCursor.arrow
    }
}

//
// MARK - Curves draws
//
extension IMPCurvesView {
    
    private func drawGrid(dirtyRect: NSRect)  {
        
        gridColor.set()
        let noHLines = gridDimension.0
        let noVLines = gridDimension.1
        
        let vSpacing = dirtyRect.size.height / CGFloat(noHLines)
        let hSpacing = dirtyRect.size.width / CGFloat(noVLines)
        
        let bPath:NSBezierPath = NSBezierPath()
        
        bPath.lineWidth = gridWidth
        
        for i in 1...noHLines{
            let pos = CGFloat(i) * vSpacing + dirtyRect.origin.y
            bPath.move(to: NSMakePoint(dirtyRect.origin.x+gridAxisWidth,    pos))
            bPath.line(to: NSMakePoint(dirtyRect.size.width+dirtyRect.origin.x, pos))
        }
        bPath.stroke()
        
        for i in 1...noVLines{
            let pos = CGFloat(i) * hSpacing + dirtyRect.origin.x
            bPath.move(to: NSMakePoint(pos, dirtyRect.origin.y+gridAxisWidth))
            bPath.line(to: NSMakePoint(pos, dirtyRect.size.height+dirtyRect.origin.y))
        }
        bPath.stroke()
        
        let boldPath:NSBezierPath = NSBezierPath()
        boldPath.lineWidth = gridWidth 
        var pos = CGFloat(noVLines/2) * vSpacing + dirtyRect.origin.y
        boldPath.move(to: NSMakePoint(dirtyRect.origin.x+gridAxisWidth,    pos))
        boldPath.line(to: NSMakePoint(dirtyRect.size.width+dirtyRect.origin.x, pos))

        pos = CGFloat(noHLines/2) * hSpacing + dirtyRect.origin.x
        boldPath.move(to: NSMakePoint(pos, dirtyRect.origin.y+gridAxisWidth))
        boldPath.line(to: NSMakePoint(pos, dirtyRect.size.height+dirtyRect.origin.y))
        
        gridBoldColor.set()
        boldPath.stroke()
        
        var grad:NSGradient?
        
        if let info = activeCurve {
            grad = NSGradient(colors: [ colorOf(info: info, alpha: CGFloat(gridAxisGradient.start)), colorOf(info: info, alpha: gridAxisGradient.end)])
        }
        else {
            if let gc = gridColor.usingColorSpace(NSColorSpace.deviceRGB) {
                let c1 = NSColor(red: gc.redComponent,   green: gc.greenComponent, blue: gc.blueComponent, alpha: CGFloat(gridAxisGradient.start))
                let c2 = NSColor(red: gc.redComponent,   green: gc.greenComponent, blue: gc.blueComponent, alpha: CGFloat(gridAxisGradient.end))
                grad = NSGradient(colors: [ c1, c2])
            }
        }
        
        var rect = NSRect(x: dirtyRect.origin.x,
                          y: dirtyRect.origin.y,
                          width: dirtyRect.size.width+gridWidth,
                          height: gridAxisWidth+gridWidth)
        
        grad?.draw(in: rect, angle: 0)
        
        rect = NSRect(x: dirtyRect.origin.x,
                      y: dirtyRect.origin.y,
                      width: gridAxisWidth+gridWidth,
                      height:dirtyRect.size.height+gridWidth)
        
        grad?.draw(in: rect, angle: 90)

    }
    
    private func colorOf(info:IMPCurveViewInfo, alpha:CGFloat = 1) -> NSColor {
        if info.isActive {
            return info.color.withAlphaComponent(alpha)
        }
        return info.color.withAlphaComponent(alpha*nonActiveLineAlpha)
    }
    
    private func clampColorOf(info:IMPCurveViewInfo, alpha:CGFloat = 1) -> NSColor {
        if info.isActive {
            return info.clampColor.withAlphaComponent(alpha)
        }
        return info.clampColor.withAlphaComponent(alpha*nonActiveLineAlpha)
    }
    
    private func drawCurve(dirtyRect: NSRect, info:IMPCurveViewInfo){
        
        guard let curve = info.curve else { return }

        guard curve.controlPoints.count>=2 else {
            return
        }
        
        var d:[CGFloat] = [5,4]

        let leftPoint = NSPoint(x: dirtyRect.size.width * CGFloat(curve.controlPoints[0].x) + dirtyRect.origin.x,
                                y: dirtyRect.size.height * CGFloat(curve.controlPoints[0].y) + dirtyRect.origin.y)
    
        let rightPoint = NSPoint(x: dirtyRect.size.width * CGFloat(curve.controlPoints[curve.controlPoints.count-1].x) + dirtyRect.origin.x,
                                y: dirtyRect.size.height * CGFloat(curve.controlPoints[curve.controlPoints.count-1].y) + dirtyRect.origin.y)
        

        if curve.type == .interpolated {

            let clapmedOffset = info.isActive ? markerSize/2 : 0
            
            let clampedPath = NSBezierPath()
            clampedPath.lineWidth = lineWidth
        
            if info.isActive {
                var dc:[CGFloat] = info.isHover ? d : [3,3]
                clampedPath.setLineDash(&dc, count: 2, phase: 0)
            }
            
            var startPoint = leftPoint
            startPoint.x = gridAxisWidth + lineWidth + dirtyRect.origin.x
            
            clampColorOf(info: info).set()
            
            clampedPath.move(to: startPoint)
            var lp = leftPoint
            
            lp.x -= clapmedOffset+lineWidth/2
            
            clampedPath.line(to: lp)
            
            var rp = rightPoint
            rp.x += clapmedOffset + lineWidth/2
            var endPoint = rightPoint
            endPoint.x = dirtyRect.size.width + dirtyRect.origin.x

            clampedPath.move(to: rp)
            clampedPath.line(to: endPoint)

            clampedPath.stroke()
        
        }
        
        colorOf(info: info).set()

        let path = NSBezierPath()
        path.lineJoinStyle = .round
        path.lineCapStyle = .round
        
        path.fill()
        if info.isHover{
            path.setLineDash(&d, count: 2, phase: 0)
            
        }
        
        path.lineWidth = lineWidth * (info.isActive ? activeLineScale : 1)
        
        let fx = curve.type == .interpolated ? leftPoint.x + markerSize/2 + lineWidth/2 : dirtyRect.origin.x
        let fy = curve.type == .interpolated ? leftPoint.y : dirtyRect.origin.y
        
        path.move(to: NSPoint(x:fx, y:fy))
        
        for i in 0..<curve.values.count {
                        
            let t = Float(i) / Float(curve.values.count-1)
            
            let w = dirtyRect.size.width * CGFloat(t)
            let x = w + dirtyRect.origin.x
            let y = curve.values[i].cgfloat*dirtyRect.size.height + dirtyRect.origin.y
            
            let p = NSPoint(x: x, y: y)
                        
            if curve.type == .interpolated {
                guard x<=rightPoint.x else { break }
            }

            if x < fx - markerSize/2 {
                path.move(to: p)
            }
            else {
                path.line(to: p)
            }
        }
        
        if curve.type == .interpolated {
            path.line(to: rightPoint)
        }
        
        path.stroke()
    }
    
    private func drawControlPoints(dirtyRect: NSRect, info:IMPCurveViewInfo) {
        
        guard let curve = info.curve else { return }

        let cp = currentPoint ?? float2(repeating: -1)
        
        let markerSizeHere = markerSize

        let boldPathColor =  NSColor.clear
        let pathColor     = colorOf(info: info)
        let mColor        = clampColorOf(info: info)
        
        for (i,p) in curve.controlPoints.enumerated() {
            
            let boldPath = NSBezierPath()
            boldPath.lineWidth = lineWidth

            let fillPath = NSBezierPath()
            fillPath.lineWidth = 0

            let path = NSBezierPath()
            path.lineWidth = lineWidth
            
            let isClosennes = curve.closeness(one: cp, two: p, distance: 1/Float(curve.values.count))
            
            let np = NSPoint(x:p.x.cgfloat*dirtyRect.width  + dirtyRect.origin.x,
                             y:p.y.cgfloat*dirtyRect.height + dirtyRect.origin.y)
                        
            let rect = NSRect(
                x: np.x-markerSizeHere/2,
                y: np.y-markerSizeHere/2,
                width: markerSizeHere, height: markerSizeHere)
   
            let rectFill = NSRect(
                x: np.x-(markerSizeHere/2-lineWidth/2),
                y: np.y-(markerSizeHere/2-lineWidth/2),
                width: (markerSizeHere-lineWidth), height: (markerSizeHere-lineWidth))
            
            var mt = markerType
            if i == 0 || i == curve.controlPoints.count-1 {
                mt = edgeMarkerType
                mColor.set()
            }
            else {
                if isClosennes {
                    pathColor.set()
                }
                else {
                    boldPathColor.set()
                }
            }

            if  isClosennes  {
                
                switch mt {
                case .arc:
                    path.appendArc(withCenter: np, radius: markerRadius, startAngle: 0, endAngle: 360)
                    boldPath.appendArc(withCenter: np, radius: markerRadius, startAngle: 0, endAngle: 360)
                    fillPath.appendArc(withCenter: np, radius: markerRadius-lineWidth/2, startAngle: 0, endAngle: 360)
                default:
                    path.appendRect(rect)
                    boldPath.appendRect(rect)
                    fillPath.appendRect(rectFill)
                }
                
                path.stroke()
                boldPath.fill()
                
                //markerFillColor.set()
                boldPathColor.set()
                fillPath.fill()
            }
            else {
                
                switch mt {
                case .arc:
                    boldPath.appendArc(withCenter: np, radius: markerRadius, startAngle: 0, endAngle: 360)
                    fillPath.appendArc(withCenter: np, radius: markerRadius-lineWidth/2, startAngle: 0, endAngle: 360)
                default:
                    boldPath.appendRect(rect)
                    fillPath.appendRect(rectFill)
                }
                
                boldPath.fill()
                
                if i == 0 || i == curve.controlPoints.count-1 {
                    mColor.set()
                }
                else {
                    pathColor.set()
                }
                
                switch mt {
                case .arc:
                    path.appendArc(withCenter: np, radius: markerRadius, startAngle: 0, endAngle: 360)
                default:
                    path.appendRect(rect)
                }
                path.stroke()
                                    
                markerFillColor.set()
                fillPath.fill()
            }
        }
    }
    
    override public func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
             
        let rect = NSInsetRect(dirtyRect, padding.dX, padding.dY)
        
        drawGrid(dirtyRect: rect)
        
        for (_,l) in self.list.enumerated() {            
            drawCurve(dirtyRect: rect, info: l)
        }
                
        for i in list {
            guard i.isActive else { continue } 
            drawControlPoints(dirtyRect: rect, info: i)
        }
    }
}

     fileprivate extension NSImage {                    
        convenience init(symbol:String, color: NSColor, size:NSSize, font:NSFont? = nil) {
            self.init(size: size)
                            
            let rect = NSRect(x: 0, y: 0, width: size.width, height: size.height)
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byClipping
            style.alignment = .center
            
            let font = font ?? NSFont(name: "Courier", size: size.height)
                        
            lockFocus()

            symbol.draw(in: rect, withAttributes: [NSAttributedString.Key.paragraphStyle : style,
                                                  NSAttributedString.Key.foregroundColor: color,
                                                  NSAttributedString.Key.font: font ?? NSFont.systemFont(ofSize: 12)])
            
            unlockFocus()
        }                
    }
#endif
