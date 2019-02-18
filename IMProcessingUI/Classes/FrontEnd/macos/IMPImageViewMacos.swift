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
                    //CATransaction.commit()                    
                }
            })
        }
    }
        
    /// Image preview window
    open class IMPImageView: IMPViewBase{

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

        open var contentView:IMPViewBase {
            return _imageView
        }
        
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
                
        private var isSizeFit = true
        
        ///  Fite image to current view size
        public func sizeFit(){
            isSizeFit = true
            _scrollView.magnify(toFit: _imageView.bounds)
        }
        
        public func imageMove(_ distance:NSPoint) {
            if let rect = _scrollView.documentView?.visibleRect {
                var point = rect.origin
                point = NSPoint(x: point.x + distance.x, y: point.y + distance.y) 
                _scrollView.documentView?.scroll(point)
            }
        }
        
        ///  Present image in oroginal size
        public func sizeOriginal(at point:NSPoint? = nil){
            isSizeFit = false            
            let size = _scrollView.visibleRect.size
            let origSize = _imageView.drawableSize
            var scale = max(origSize.width/size.width, origSize.height/size.height)
            scale = scale < 1 ? 1 : scale
            _scrollView.magnify(at: point, scale: scale)
        }
        
        ///  Scale image 
        public func scale(_ scale: CGFloat, at point:NSPoint? = nil){
            isSizeFit = false            
            _scrollView.magnify(at: point, scale: scale)
        }
                
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
        
        override open func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            if isSizeFit {
                sizeFit()
            }
        }
        
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
            
            _scrollView.drawsBackground = false
            _scrollView.wantsLayer = true
            _scrollView.layer?.backgroundColor = NSColor.clear.cgColor
            
            _scrollView.allowsMagnification = true
            _scrollView.acceptsTouchEvents = true
            _scrollView.hasVerticalScroller = true
            _scrollView.hasHorizontalScroller = true
            
            _scrollView.autoresizingMask = [.height, .width]
            
            _imageView = IMPView(frame: self.bounds)
            _imageView.wantsLayer = true
            _imageView.layer?.backgroundColor = NSColor.clear.cgColor
            
            _scrollView.documentView = _imageView
            
            addSubview(_scrollView)
            
            configure()
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
        
        override open func magnify(toFit rect: NSRect) {
            super.magnify(toFit: rect)
            self.cv.moveToCenter(always: true)
        }
        
        open func magnify(at point: NSPoint?, scale:CGFloat) {
            if let p = point { 
                setMagnification(scale, centeredAt: p)
                //documentView?.scroll(p)
                scroll(p)
                reflectScrolledClipView(self.cv)
            }
            else {                
                setMagnification(scale, centeredAt: cv.midViewPoint)
                cv.moveToCenter()
            }
        }
        
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
    
    open class IMPClipView:NSClipView {
        
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
    
    
#endif

