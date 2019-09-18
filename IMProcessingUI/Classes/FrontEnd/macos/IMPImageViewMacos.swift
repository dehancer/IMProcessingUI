//
//  IMPImageViewMacos.swift
//  Pods
//
//  Created by Denis Svinarchuk on 12/04/2017.
//
//

import IMProcessing

#if os(OSX)

public extension NSScrollView {
    //        open var backgroundColor:NSColor? {
    //            set{
    //                wantsLayer = true
    //                layer?.backgroundColor = newValue?.cgColor
    //            }
    //            get{
    //                if let c = layer?.backgroundColor {
    //                    return NSColor(cgColor: c)
    //                }
    //                return nil
    //            }
    //        }
}

import AppKit

public extension IMPImageView {
    
    public func updateFrameSize()  {
        if let texture = filter?.source?.texture{
            self.updateFrameSize(texture: texture)
        }
    }
    
    public func updateFrameSize(texture:MTLTexture)  {
        let w = (texture.width.float/IMPView.scaleFactor).cgfloat
        let h = (texture.height.float/IMPView.scaleFactor).cgfloat
        DispatchQueue.main.async(execute: {
            if w != self._imageView.frame.size.width || h != self._imageView.frame.size.height {
                //CATransaction.begin()
                //CATransaction.setDisableActions(true)
                self._imageView.frame = CGRect(x: 0, y: 0,
                                               width:  w,
                                               height: h)
                self.zoomToFit()
                //CATransaction.commit()
            }
        })
    }
}

/// Image preview window
open class IMPImageView: IMPViewBase{
    
    /**
     Zooms in on the image.  In other words, expands or scales the image up.
     - parameters:
     - sender: The object that sent the event. The parameter is set to be optional so that it can be called with nil.
     */
    public func zoomIn() {
        if zoomFactor + 0.1 > container.maxMagnification {
            zoomFactor = container.maxMagnification
        } else if zoomFactor == container.minMagnification {
            zoomFactor = container.minMagnification + 0.1
        } else {
            zoomFactor += 0.1
        }
    }
    
    /**
     Zooms out on the image.  In other words, shrinks or scales the image down.
     - parameters:
     - sender: The object that sent the event. The parameter is set to be optional so that it can be called with nil.
     */
    public func zoomOut() {
        if zoomFactor - 0.1 < container.minMagnification {
            zoomFactor = container.minMagnification
        } else {
            zoomFactor -= 0.1
        }
    }
    
    /**
     Sets the image to it's default size.
     - parameters:
     - sender: The object that sent the event. The parameter is set to be optional so that it can be called with nil.
     */
    public func zoomToActual() {
        zoomFactor = 1.0
    }
    
    /**
     Fits the image entirely in the Scroll View content area (it's Clip View), using proportional scaling up or down.
     - parameters:
     - sender: The object that sent the event. The parameter is set to be optional so that it can be called with nil.
     */
    public func zoomToFit() {
        zoomFactor = givenScale
    }
    
    public var zoomFactor:CGFloat = 1.0 {
        /**
         Updates the Document View size whenever the zoomFactor is changed.
         */
        didSet {
            
            isSizeFit = true
            
            guard imageView?.filter?.source != nil else {
                return
            }
            
            OperationQueue.main.addOperation {
                self._scrollView.magnification = self.zoomFactor
            }
        }
    }
    
    open func configure(){}
    
    public var viewReadyHandler:(()->Void)? {
        set{
            _imageView.viewReadyHandler = newValue
        }
        get{
            return _imageView.viewReadyHandler
        }
    }
    
    public var viewBufferCompleteHandler:((_ image:IMPImageProvider)->Void)? {
        set{
            _imageView.viewBufferCompleteHandler = newValue
        }
        get{
            return _imageView.viewBufferCompleteHandler
        }
    }
    
    public var imageView:IMPView? {
        set{
            if newValue != nil {
                _imageView = newValue
            }
            _scrollView.documentView = newValue
        }
        get {
            return _imageView
        }
    }
    
    public var container:IMPScrollView { return _scrollView }

    
//    open var contentView:IMPViewBase {
//        return _imageView
//    }
    
    public var dragOperation:IMPDragOperationHandler? {
        didSet{
            _imageView.dragOperation = dragOperation
        }
    }
    
    public func addOverlayView(_ view: NSView) {
        _imageView.addSubview(view)
    }
    
    /// View filter
    public var filter:IMPFilter?{
        willSet{
            filter?.removeObserver(destinationUpdated: destinationUpdated)
        }
        didSet{
            _imageView?.filter = filter
            filter?.addObserver(destinationUpdated: destinationUpdated)
        }
    }
    
    private lazy var  destinationUpdated:IMPFilter.UpdateHandler = {
        let handler:IMPFilter.UpdateHandler = { destination in
            if let texture = destination.texture{
                self.updateFrameSize(texture: texture)
            }
        }
        return handler
    }()
    
    public var isPaused:Bool {
        set{
            _imageView.isPaused = newValue
        }
        get {
            return _imageView.isPaused
        }
    }
    
    ///  Magnify image to fit rectangle
    ///
    ///  - parameter rect: rectangle which is used to magnify the image to fit size an position
    public func magnifyToFitRect(rect:CGRect){
        isSizeFit = false
        _scrollView.magnify(toFit: rect)
    }
    
//    private var isSizeFit:Bool {
//        set{
//            _scrollView.cv.isSizeFit = newValue
//        }
//        get{
//            return _scrollView.cv.isSizeFit
//        }
//    }
    
    private var isSizeFit = true {
        didSet{
            _scrollView.cv.isSizeFit = isSizeFit
        }
    }
    
    ///  Fite image to current view size
//    public func sizeFit(){
//        isSizeFit = true
//        _scrollView.magnify(toFit: _imageView.bounds)
//    }
    
    public func imageMove(_ distance:NSPoint) {
        if let rect = _scrollView.documentView?.visibleRect {
            var point = rect.origin
            point = NSPoint(x: point.x + distance.x, y: point.y + distance.y)
            _scrollView.documentView?.scroll(point)
        }
    }
    
//    ///  Present image in oroginal size
//    public func sizeOriginal(at point:NSPoint? = nil){
//        isSizeFit = false
//        let size = _scrollView.visibleRect.size
//        let origSize = _imageView.drawableSize
//        var scale = max(origSize.width/size.width, origSize.height/size.height)
//        scale = scale < 1 ? 1 : scale
//        _scrollView.magnify(at: point, scale: scale)
//    }
//
//    ///  Scale image
//    public func scale(_ scale: CGFloat, at point:NSPoint? = nil){
//        isSizeFit = false
//        _scrollView.magnify(at: point, scale: scale)
//    }
    
    @objc func magnifyChanged(event:NSNotification){
        isSizeFit = false
    }
    
    public var scrollView:IMPScrollView {
        return _scrollView
    }
    
    public init(){
        super.init(frame: NSRect())
        defer{
            self._configure()
        }
    }
    
    ///  Create image view object with th context within properly frame
    ///
    ///  - parameter frame:     view frame rectangle
    ///
    public override init(frame: NSRect){
        super.init(frame: frame)
        defer{
            self._configure()
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        defer{
            self._configure()
        }
    }
    
//    override open func setFrameSize(_ newSize: NSSize) {
//        super.setFrameSize(newSize)
//        if isSizeFit {
//            sizeFit()
//        }
//    }
    
    public func addMouseEventObserver(observer:@escaping IMPView.MouseEventHandler){
        _imageView.addMouseEventObserver(observer: observer)
    }
    
    public var imageArea:NSRect {
        var frame = _imageView.frame
        frame.origin.x += _scrollView.contentInsets.left
        frame.origin.y += _scrollView.contentInsets.top
        frame.size.width -= _scrollView.contentInsets.right
        frame.size.height -= _scrollView.contentInsets.bottom
        return frame
    }
    
    fileprivate var _imageView:IMPView!
    private var _scrollView:IMPScrollView!
    
    private func _configure(){
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(magnifyChanged(event:)),
            name: NSScrollView.willStartLiveMagnifyNotification,
            object: nil)
        
        _scrollView = IMPScrollView(frame: bounds)
        
//        _scrollView.drawsBackground = false
//        _scrollView.wantsLayer = true
//        _scrollView.layer?.backgroundColor = NSColor.clear.cgColor
//
//        _scrollView.allowsMagnification = true
//        _scrollView.acceptsTouchEvents = true
//        _scrollView.hasVerticalScroller = true
//        _scrollView.hasHorizontalScroller = true
//
//        _scrollView.autoresizingMask = [.height, .width]
//
//        _imageView = IMPView(frame: self.bounds)
//        _imageView.wantsLayer = true
//        _imageView.layer?.backgroundColor = NSColor.clear.cgColor
//
//        _scrollView.documentView = _imageView
//
//        container.documentView?.autoresizingMask = [.width, .height]

        //_scrollView.contentView =
        _scrollView.hasVerticalRuler = true
        _scrollView.hasHorizontalRuler = false
        _scrollView.rulersVisible = false
        _scrollView.scrollsDynamically = false
        _scrollView.autoresizingMask = [.width,.height]
        _scrollView.wantsLayer = true
        _scrollView.drawsBackground = false
        _scrollView.automaticallyAdjustsContentInsets = true
        _scrollView.contentInsets = NSEdgeInsetsMake(10, 4, 10, 4)
        
        _scrollView.allowsMagnification = true
        _scrollView.maxMagnification = 4
        _scrollView.minMagnification = 0.2
        if #available(OSX 10.12.2, *) {
            _scrollView.allowedTouchTypes = .direct
        } else {
            // Fallback on earlier versions
        }
        _scrollView.documentView = _imageView
        
        addSubview(_scrollView)
        
        _scrollView.magnification = 1
        zoomFactor = 1
        
        configure()
    }
    
    private var givenScale:CGFloat {
        
        guard imageView?.filter?.source != nil else {
            return 1
        }
        
        let imSize = screenImageSize
        
        var clipSize = bounds.size
        
        let imageMargin:CGFloat = 0
        
        clipSize.width -= imageMargin
        clipSize.height -= imageMargin
        
        guard imSize.width > 0 && imSize.height > 0 && clipSize.width > 0 && clipSize.height > 0 else {
            return 1
        }
        
        let clipAspectRatio = clipSize.width / clipSize.height
        let imAspectRatio = imSize.width / imSize.height
        
        if clipAspectRatio > imAspectRatio {
            return imSize.height / clipSize.height
        } else {
            return imSize.width / clipSize.width
        }
    }
    
    private var screenImageSize:NSSize {
        return imageView?.filter?.source?.size  ?? .zero
    }
    
}

open class IMPScrollView:NSScrollView {
    
    fileprivate var cv:IMPClipView!
    
    open func configure(){}
    
    private func _configure(){
        //postsFrameChangedNotifications = true
        
        cv = IMPClipView(frame: self.bounds)
        contentView = cv
        
        let vs = IMPScroller()
        vs.scrollView = self
        vs.fadeOut()
        verticalScroller = vs
        verticalScroller?.controlSize = NSControl.ControlSize.mini
        
        let hs = IMPScroller()
        hs.scrollView = self
        hs.fadeOut()
        horizontalScroller = hs
        horizontalScroller?.controlSize = NSControl.ControlSize.mini
        
        verticalScroller?.scrollerStyle = .overlay
        horizontalScroller?.scrollerStyle = .overlay
        
        configure()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self._configure()
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self._configure()
    }
    
//    override open func magnify(toFit rect: NSRect) {
//        super.magnify(toFit: rect)
//        self.cv.moveToCenter(always: true)
//    }
    
//    open func magnify(at point: NSPoint?, scale:CGFloat) {
//        if let p = point {
//            setMagnification(scale, centeredAt: p)
//            //documentView?.scroll(p)
//            scroll(p)
//            reflectScrolledClipView(self.cv)
//        }
//        else {
//            setMagnification(scale, centeredAt: cv.midViewPoint)
//            cv.moveToCenter()
//        }
//    }
    
    override open func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
    }
    
    override open func tile() {
        super.tile()
        contentView.frame  = bounds
    }
}

open class IMPScroller: NSScroller {
    
    var scrollView:IMPScrollView!
    
    override open class var preferredScrollerStyle: NSScroller.Style { return .overlay  }
    
    override open func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
        drawKnob()
    }
    
    var trackingTag:NSView.TrackingRectTag?
    var trackState:Int = 284
    
    override open func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingTag{
            removeTrackingRect(t)
        }
        trackingTag = addTrackingRect(bounds, owner: self, userData: &trackState, assumeInside: true)
    }
    
    func drawBackground(rect:NSRect) {
        let width = min(rect.width,rect.height)
        let path = NSBezierPath(roundedRect: rect, xRadius: width/2 , yRadius: width/2)
        NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha:0.5).set()
        path.fill()
    }
    
    override open func drawKnob() {
        drawBackground(rect: rect(for: NSScroller.Part.knob))
    }
    
    override open func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        super.drawKnobSlot(in: slotRect, highlight: true)
        NSColor.clear.set()
        slotRect.fill()
    }
    
    override open func mouseExited(with theEvent:NSEvent){
        super.mouseExited(with: theEvent)
        self.fadeOut()
    }
    
    override open func mouseEntered(with theEvent:NSEvent) {
        super.mouseEntered(with: theEvent)
        gestureEnable(false)
        
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.1
            self.animator().alphaValue = 1.0
        }, completionHandler: nil)
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.fadeOut), object: nil)
    }
    
    override open func mouseMoved(with theEvent:NSEvent){
        super.mouseMoved(with: theEvent)
        self.alphaValue = 1.0
    }
    
    func gestureEnable(_ enabled:Bool) {
        if let gs = scrollView.superview?.gestureRecognizers {
            for g in gs{
                g.isEnabled = enabled
            }
        }
    }
    
    @objc func fadeOut() {
        
        gestureEnable(true)
        
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.3
            self.animator().alphaValue = 0.0
        }, completionHandler: nil)
    }
    
}

open class IMPClipView__:NSClipView {
    
    open override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
    }
    
    public var midViewPoint:NSPoint {
        var p = NSZeroPoint
        if let documentView = self.documentView{
            let documentFrame = documentView.frame
            let clipFrame     = self.bounds
            p.x = NSMidX(clipFrame) / documentFrame.size.width;
            p.y = NSMidY(clipFrame) / documentFrame.size.height;
        }
        return p
    }
    
    override open var wantsDefaultClipping: Bool {
        return false
    }
    
    override open func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        if let documentView = self.documentView{
            
            let documentFrame:NSRect = documentView.frame
            var clipFrame     = self.bounds
            
            let x = documentFrame.size.width - clipFrame.size.width
            let y = documentFrame.size.height - clipFrame.size.height
            
            clipFrame.origin = proposedBounds.origin
            
            if clipFrame.size.width>documentFrame.size.width{
                clipFrame.origin.x = CGFloat(roundf(Float(x) / 2.0))
            }
            else{
                let m = Float(max(0, min(clipFrame.origin.x, x)))
                clipFrame.origin.x = CGFloat(roundf(m))
            }
            
            if clipFrame.size.height>documentFrame.size.height{
                clipFrame.origin.y = CGFloat(roundf(Float(y) / 2.0))
            }
            else{
                let m = Float(max(0, min(clipFrame.origin.y, y)))
                clipFrame.origin.y = CGFloat(roundf(m))
            }
            
            return clipFrame
            
        }
        else{
            return super.constrainBoundsRect(proposedBounds)
        }
    }
    
    //        func moveTo(point:NSPoint, always:Bool = true){
    //            if let documentView = self.documentView{
    //
    //                let documentFrame = documentView.frame
    //                var clipFrame     = self.bounds
    //
    //                if documentFrame.size.width < clipFrame.size.width || always {
    //                    clipFrame.origin.x = CGFloat(roundf(Float(documentFrame.size.width - clipFrame.size.width) / 2.0));
    //                } else {
    //                    clipFrame.origin.x = CGFloat(roundf(Float(point.x * documentFrame.size.width - (clipFrame.size.width) / 2.0)));
    //                }
    //
    //                if documentFrame.size.height < clipFrame.size.height || always {
    //                    clipFrame.origin.y = CGFloat(roundf(Float(documentFrame.size.height - clipFrame.size.height) / 2.0));
    //                } else {
    //                    clipFrame.origin.y = CGFloat(roundf(Float(point.y * documentFrame.size.height - (clipFrame.size.height) / 2.0)));
    //                }
    //
    //                let scrollView = self.superview
    //
    //
    //                Swift.print("clipFrame = \(point, clipFrame, NSPointInRect(point, clipFrame), self.constrainBoundsRect(clipFrame).origin)")
    //                if NSPointInRect(point, clipFrame) {
    //                    //self.scroll(to: self.constrainBoundsRect(clipFrame).origin)
    //                    self.scroll(to: point)
    //                }
    //                scrollView?.reflectScrolledClipView(self)
    //            }
    //        }
    
    func moveToCenter(always:Bool = true){
        if let documentView = self.documentView{
            
            let documentFrame = documentView.frame
            var clipFrame     = self.bounds
            
            let point = midViewPoint
            
            if documentFrame.size.width < clipFrame.size.width || always {
                clipFrame.origin.x = CGFloat(roundf(Float(documentFrame.size.width - clipFrame.size.width) / 2.0));
            } else {
                clipFrame.origin.x = CGFloat(roundf(Float(point.x * documentFrame.size.width - (clipFrame.size.width) / 2.0)));
            }
            
            if documentFrame.size.height < clipFrame.size.height || always {
                clipFrame.origin.y = CGFloat(roundf(Float(documentFrame.size.height - clipFrame.size.height) / 2.0));
            } else {
                clipFrame.origin.y = CGFloat(roundf(Float(point.y * documentFrame.size.height - (clipFrame.size.height) / 2.0)));
            }
            
            let scrollView = self.superview
            
            self.scroll(to: self.constrainBoundsRect(clipFrame).origin)
            scrollView?.reflectScrolledClipView(self)
        }
    }
    
    override open func viewFrameChanged(_ notification: Notification) {
        let scrollView = self.superview as! IMPScrollView
        if scrollView.documentView?.postsFrameChangedNotifications ?? false {
            super.viewFrameChanged(notification as Notification)
        }
    }
    
    override open var documentView:NSView?{
        didSet{
            self.moveToCenter()
        }
    }
}

open class IMPClipView: NSClipView {
    
    public var isCenteringEnabled = true
    
    open var isSizeFit = true
    
    override open func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        
        if !isCenteringEnabled {
            return super.constrainBoundsRect(proposedBounds)
        }
        
        guard let documentView = documentView else { return super.constrainBoundsRect(proposedBounds) }
        
        var newClipBoundsRect = super.constrainBoundsRect(proposedBounds)
        
        
        // Get the `contentInsets` scaled to the future bounds size.
        
        let insets = convertedContentInsetsToProposedBoundsSize(proposedBoundsSize: newClipBoundsRect.size)
        
        
        // Get the insets in terms of the view geometry edges, accounting for flippedness.
        
        let minYInset = isFlipped ? insets.top : insets.bottom
        
        let maxYInset = isFlipped ? insets.bottom : insets.top
        
        let minXInset = insets.left
        
        let maxXInset = insets.right
        
        
        /*
         
         Get and outset the `documentView`'s frame by the scaled contentInsets.
         
         The outset frame is used to align and constrain the `newClipBoundsRect`.
         
         */
        
        let documentFrame = documentView.frame
        
        let outsetDocumentFrame = NSRect(x: documentFrame.minX - minXInset,
                                         
                                         y: documentFrame.minY - minYInset,
                                         
                                         width: (documentFrame.width + (minXInset + maxXInset)),
                                         
                                         height: documentFrame.height + (minYInset + maxYInset))
        
        
        if !isSizeFit && (newClipBoundsRect.width < outsetDocumentFrame.width && newClipBoundsRect.height < outsetDocumentFrame.height) {
            return newClipBoundsRect
        }
        
        
        //if newClipBoundsRect.width > outsetDocumentFrame.width {
        if true {
            
            /*
             
             If the clip bounds width is larger than the document, center the
             
             bounds around the document.
             
             */
            
            newClipBoundsRect.origin.x = outsetDocumentFrame.minX - (newClipBoundsRect.width - outsetDocumentFrame.width) / 2.0
            
        }
            
        else if newClipBoundsRect.width < outsetDocumentFrame.width {
            
            /*
             
             Otherwise, the document is wider than the clip rect. Make sure that
             
             the clip rect stays within the document frame.
             
             */
            
            if newClipBoundsRect.maxX > outsetDocumentFrame.maxX {
                
                // The clip rect is outside the maxX edge of the document, bring it in.
                
                newClipBoundsRect.origin.x = outsetDocumentFrame.maxX - newClipBoundsRect.width
                
            }
                
            else if newClipBoundsRect.minX < outsetDocumentFrame.minX {
                
                // The clip rect is outside the minX edge of the document, bring it in.
                
                newClipBoundsRect.origin.x = outsetDocumentFrame.minX
                
            }
        }
        
        
        //if newClipBoundsRect.height > outsetDocumentFrame.height {
        if true {
            
            /*
             
             If the clip bounds height is larger than the document, center the
             
             bounds around the document.
             
             */
            
            newClipBoundsRect.origin.y = outsetDocumentFrame.minY - (newClipBoundsRect.height - outsetDocumentFrame.height) / 2.0
            
        }
            
        else if newClipBoundsRect.height < outsetDocumentFrame.height {
            
            /*
             
             Otherwise, the document is taller than the clip rect. Make sure
             
             that the clip rect stays within the document frame.
             
             */
            
            if newClipBoundsRect.maxY > outsetDocumentFrame.maxY {
                
                // The clip rect is outside the maxY edge of the document, bring it in.
                
                newClipBoundsRect.origin.y = outsetDocumentFrame.maxY - newClipBoundsRect.height
                
            }
                
            else if newClipBoundsRect.minY < outsetDocumentFrame.minY {
                
                // The clip rect is outside the minY edge of the document, bring it in.
                
                newClipBoundsRect.origin.y = outsetDocumentFrame.minY
                
            }
            
        }
        
        return backingAlignedRect(newClipBoundsRect, options: .alignAllEdgesNearest)
    }
    
    
    
    /**
     
     The `contentInsets` scaled to the scale factor of a new potential bounds
     
     rect. Used by `constrainBoundsRect(NSRect)`.
     
     */
    
    private func convertedContentInsetsToProposedBoundsSize(proposedBoundsSize: NSSize) -> NSEdgeInsets {
        
        // Base the scale factor on the width scale factor to the new proposedBounds.
        
        let fromBoundsToProposedBoundsFactor = bounds.width > 0 ? (proposedBoundsSize.width / bounds.width) : 1.0
        
        
        // Scale the set `contentInsets` by the width scale factor.
        
        var newContentInsets = contentInsets
        
        newContentInsets.top *= fromBoundsToProposedBoundsFactor
        
        newContentInsets.left *= fromBoundsToProposedBoundsFactor
        
        newContentInsets.bottom *= fromBoundsToProposedBoundsFactor
        
        newContentInsets.right *= fromBoundsToProposedBoundsFactor
        
        
        
        return newContentInsets
        
    }
}


#endif

