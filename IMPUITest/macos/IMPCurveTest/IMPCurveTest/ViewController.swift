//
//  ViewController.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 16.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing
import IMProcessingUI
import SnapKit
import simd
import Surge

extension NSColor {
    func reshape(alpha: CGFloat) -> NSColor {
        return NSColor(red: self.redComponent,   green: self.greenComponent, blue: self.blueComponent, alpha: alpha)
    }
}

class ViewController: NSViewController, IMPCurvesViewDelegate, IMPHistogramViewDataSource {

    let histogramOpacity:CGFloat = 0.3
    
    var rawFile:IMPRawFile? {
        didSet{
            imageView.filter?.source = rawFile
        }
    }
    
    var imagePath:String? {
        didSet{
            guard  let path = imagePath else {
                return
            }
//            rawFile = IMPRawFile(context: filter.context, 
//                                 rawFile: path, 
//                                 scale:0.5, draft:true)
            imageView.filter?.source = IMPImage(context: filter.context, 
                                                path: path, maxSize: 4000)
        }
    }
    
    let context = IMPContext()
    
    lazy var rgbHistogramAnalyzer:IMPHistogramAnalyzer = {
        var r = IMPHistogramAnalyzer(context: self.context, name:"RgbHistogramAnalyzer")
        r.maxSize = 400
        return r
    }()
  
    var colorRange = IMPHistogramRangeSolver()
    var avrgColor  = IMPHistogramDominantColorSolver()
    var adams      = IMPHistogramZonesSolver()

    lazy var resultHistogramAnalyzer:IMPHistogramAnalyzer = {
        var r = IMPHistogramAnalyzer(context: self.context, name:"ResultHistogramAnalyzer")
        r.maxSize = 400
        r.add(solver: self.colorRange){ (solver) in
//            NSLog(" range = \(self.colorRange.minimum, self.colorRange.maximum)")
        }
        r.add(solver: self.avrgColor){ (solver) in
//            NSLog(" average = \(self.avrgColor.color)")
        }
        r.add(solver: self.adams){ (solver) in
//            NSLog(" adams.zones.steps   = \(self.adams.zones.steps)")
//            NSLog(" adams.zones.balance = \(self.adams.zones.balance)")
//            NSLog(" adams.zones.spots   = \(self.adams.zones.spots)")
//            NSLog(" adams.zones.range   = \(self.adams.zones.range)")
        }
        return r
    }()

    lazy var labHistogramAnalyzer:IMPHistogramAnalyzer = {
        var l = IMPHistogramAnalyzer(context: self.context, name:"LabHistogramAnalyzer")
        l.maxSize = 400
        l.colorSpace = .lab
        l.histogram = IMPHistogram(type:.xyz)
        return l
    }()

    lazy var posterize:IMPPosterize = IMPPosterize(context: self.context)
        
    lazy var rgbHistogramView:IMPHistogramView = {
        var v = IMPHistogramView()
        v.backgroundColor = NSColor.clear
        v.dataSource = self
        return v
    }()
    
    lazy var labHistogramView:IMPHistogramView = {
        var v = IMPHistogramView()
        v.backgroundColor = NSColor.clear
        v.dataSource = self
        return v
    }()
    
    
    lazy var resultHistogramView:IMPHistogramView = {
        var v = IMPHistogramView()
        v.backgroundColor = NSColor.clear
        v.dataSource = self
        return v
    }()
    
    lazy var whiteBalance:IMPWhiteBalanceFilter = IMPWhiteBalanceFilter(context: self.context, name:"WhiteBalance")
    
    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context, name: "IMPView.filter")
        
        // 
        //
        //
        // f.addObserver(destinationUpdated: { (destination) in
        //     self.histogramAnalyzer.source = destination
        //     self.histogramAnalyzer.process()
        //     self.histogramAnalyzer.addObserver(destinationUpdated: { (destination) in
        //          ...
        //     })
        // })
        
        //
        // The above snippet is equal the follow lines sugar:
        //
//        f ==> self.labHistogramAnalyzer --> { (source) in
//            DispatchQueue.main.async {
//                self.labHistogramView.reload()
//            }
//        }
        
        //
        //
        // f.addObserver(newSource: { (source) in
        //     self.histogramAnalyzer.source = source
        //     self.histogramAnalyzer.process()
        //     self.histogramAnalyzer.addObserver(destinationUpdated: { (destination) in
        //          ...
        //     })
        // })
        //
        // The above snippet is equal the follow lines sugar:
        //
//        f ==> self.rgbHistogramAnalyzer --> { (source) in
//            DispatchQueue.main.async {
//                self.rgbHistogramView.reload()
//            }
//        }
//        
//        f --> self.resultHistogramAnalyzer --> { (source) in
//            DispatchQueue.main.async {
//                self.resultHistogramView.reload()            
//            }
//        }
//        
        f.add(filter: self.lutFilter)
        f.add(filter: self.whiteBalance)

        
        self.curvesFilter.source =  try! IMPCLut(context: self.context, lutType: .lut_2d, lutSize: 64, format: .float, compression: float2(0.0, 1.0)) //self.lutFilter.clut?.identity
                
        return f
    }()
   
    lazy var curvesFilter:IMPFilter = {
        var f = IMPFilter(context: self.context, name:"CurvesFilter")
        
        f.addObserver(destinationUpdated: { (destination) in            
            f.context.runOperation(.async) {
                do {
//                    Swift.print(" ### curvesFilter update: \(destination)")
                    try self.lutFilter.clut?.update(from: destination)
                }
                catch let error {
//                    Swift.print("### curvesFilter error: \(error)")
                }            
            }
        })
            
        f.addObserver(dirty: { (filter, source, destination) in
//            Swift.print(" ### curvesFilter dirty: \(f.name, filter.name, filter.dirty)")

            f.context.runOperation(.async) {
                f.process()
            }
        })
                
        self.posterize.levels = 256
        f.add(filter: self.posterize)        
        f.add(filter: self.rgbCurves) 
        f.add(filter: self.labCurves)     
                
        return f
    }()
    
    lazy var lutFile:String! =  Bundle.main.path(forResource: "K64PW", ofType: "cube")!
            
    lazy var lutFilter:IMPCLutFilter = IMPCLutFilter(context: self.context, lutSize: 64, format: .float, title:"IMPCLutFilter")
    
    lazy var rgbCurves:IMPCurvesFilter = {
        let f = IMPCurvesFilter(context: self.context, name: "RGB Curves")
        return f
    }()

    lazy var labCurves:IMPCurvesFilter = {
        let f =  IMPCurvesFilter(context: self.context/*, name: "Lab Curves"*/)
        f.colorSpace = .lab
        return f
    }()
    
    let bg = NSColor(deviceWhite: 0.1, alpha: 1)
    
    
    lazy var rgbInfo = IMPCurveViewInfo.rgb()
    lazy var labInfo = IMPCurveViewInfo.lab()
    
    lazy var rgbCurveView:IMPCurvesView = {
        var v = IMPCurvesView()
        
        let info = self.rgbInfo

        for i in info {
            i.deferrable.delay = 1/240
        }
        
        
        /*info[0].curve = IMPCurveCollection.polyline.curve
        info[1].curve = IMPCurveCollection.bezier.curve
        info[2].curve = IMPCurveCollection.catmullRom.curve
        info[3].curve = IMPCurveCollection.bspline.curve*/
    
        self.rgbCurves.master   = info[0].curve
        self.rgbCurves.channels = [info[1].curve,info[2].curve,info[3].curve]
        
        v.info = info

        v.markerFillColor = self.bg
        v.markerType = .rect
        v.edgeMarkerType = .arc
        v.precision = 0.03
        v.delegate = self
        
        return v
    }()
    
    lazy var labCurveView:IMPCurvesView = {
        var v = IMPCurvesView()
        v.info = self.labInfo
        self.labCurves.channels = [v.info[0].curve,v.info[1].curve,v.info[2].curve]
        v.delegate = self
        v.markerFillColor = self.bg
        v.lineWidth = 1.5
        return v
    }()
    
    ///
    /// Histogram data source
    ///
    var currentLabChannleSelected:Int? { didSet{labHistogramView.reload() }}
    var currentRgbChannleSelected:Int? { didSet{rgbHistogramView.reload() }}
    
    func histogram(view: IMPHistogramView) -> IMPHistogram {
        if view === labHistogramView {
            return labHistogramAnalyzer.histogram
        }
        else if view  == rgbHistogramView {
            return rgbHistogramAnalyzer.histogram
        }
        else {
            return resultHistogramAnalyzer.histogram
        }
    }
    
    func histogram(view: IMPHistogramView, clampColorForChannel index: Int) -> NSColor {
        if view === labHistogramView {
            if let i = currentLabChannleSelected {
                return labInfo[i].clampColor
            }
        }
        else if view === rgbHistogramView {
            if let i = currentRgbChannleSelected {
                return rgbInfo[i].clampColor
            }
        }
        return NSColor.clear
    }
    
    func histogram(view: IMPHistogramView, clampEdgesForChannel index: Int) -> (left: CGFloat, right: CGFloat) {
        if view === labHistogramView {
            if let i = currentLabChannleSelected {
                let cp = labInfo[i].controlPoints
                return (cp[0].x.cgfloat,cp[cp.count-1].x.cgfloat)
            }
        }
        else if view === rgbHistogramView {
            if let i = currentRgbChannleSelected {
                let cp = rgbInfo[i].controlPoints
                return (cp[0].x.cgfloat,cp[cp.count-1].x.cgfloat)
            }
        }
        return (0,1)
    }

    func histogram(view: IMPHistogramView, fillColorForChannel index: Int) -> NSColor {
        if view === labHistogramView {
            return labInfo[index].color
        }
        else {
            return rgbInfo[index].color
        }
    }
    
    
    func histogram(view: IMPHistogramView, shouldVisibleForChannel index: Int) -> Bool {
        if view === labHistogramView {
            if let c = currentLabChannleSelected {
                return  c == index
            }
        }
        else if view === rgbHistogramView {
            if let c = currentRgbChannleSelected {
                return c == index
            }
        }
        else if view === resultHistogramView {
            return index == 0
        }
        return true
    }
        
    ///
    /// Curves delegate
    ///
    func curvesView(_ view: IMPCurvesView, didUpdate info: IMPCurveViewInfo) {
        if (view == labCurveView) && currentLabChannleSelected != nil {
            labHistogramView.reload()
        }
        else if currentRgbChannleSelected != nil {
            rgbHistogramView.reload()
        }
    }
    
    func curvesView(_ view: IMPCurvesView, didDeselect info: IMPCurveViewInfo) {
        if (view == labCurveView){            
            currentLabChannleSelected = nil
        }
        else {
            currentRgbChannleSelected = nil
        }
    }

    func curvesView(_ view: IMPCurvesView, didSelect info: IMPCurveViewInfo) {
        if (view == labCurveView){
            currentLabChannleSelected = info.index
        }
        else {
            currentRgbChannleSelected = info.index
        }
    }

    func curvesView(_ view: IMPCurvesView, didHighlight info: IMPCurveViewInfo) {
        //NSLog("ViewController: didHighlight = \(info.name) ")
    }
   
    func curvesView(_ view: IMPCurvesView, didAdd info: IMPCurveViewInfo, points: [float2]) {
        //NSLog("ViewController: didAdd = \(info.name)  points = \(points)")
    }
   
    func curvesView(_ view: IMPCurvesView, didRemove info: IMPCurveViewInfo, points: [float2]) {
        //NSLog("ViewController: didRemove = \(info.name)  points = \(points)")
    }
    
    lazy var biasSlider:NSSlider = NSSlider(value: 0, minValue: -100, maxValue: 100, target: self, action: #selector(biasHanlder(sender:)))
    
    @objc func biasHanlder(sender:NSSlider)  {
        
        //rawFile?.bias = sender.floatValue
        rawFile?.boost = sender.floatValue/100 + 1 

        //let curve  = rgbCurveView.info[2].curve
        //let spline = curve?.interpolator as? IMPCatmulRomSpline

        //spline?.tension = sender.floatValue
        //curve?.update()
    }
    
    lazy var curvesContainer:NSView = NSView()
    
    lazy var imageView:IMPImageView = {
        
        let v = IMPImageView(frame: self.view.bounds)
        
        v.imageView?.isPaused = false
        //v.imageView?.exactResolutionEnabled = true
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.clear.cgColor
        v.filter =  self.filter
        
        var hasNewSource = false
        v.filter?.addObserver(newSource: { (source) in
            hasNewSource = true
        })
        
        v.filter?.addObserver(destinationUpdated: { (destination) in
            if hasNewSource {
                hasNewSource = false
                DispatchQueue.main.async{
                    v.sizeFit()
                }
            }
        })
        
        return v
    }()

    lazy var slider:NSSlider = NSSlider(value: 256, minValue: 1, maxValue: 256, target: self, action: #selector(sliderHandler(slider:)))
    
    @objc func sliderHandler(slider:NSSlider)  {
        //self.posterize.levels = slider.floatValue
        self.lutFilter.adjustment.blending.opacity = slider.floatValue/256 
    }
    
    
    lazy var tempSlider:NSSlider = NSSlider(value: 5000, minValue: 2000, maxValue: 9000, target: self, action: #selector(tempSliderHandler(slider:)))
    lazy var tintSlider:NSSlider = NSSlider(value: 0, minValue: -1500, maxValue: 1500, target: self, action: #selector(tintSliderHandler(slider:)))

    @objc func tempSliderHandler(slider:NSSlider)  {
        whiteBalance.temperature = slider.floatValue
        //rawFile?.temperature = slider.floatValue
    }

    @objc func tintSliderHandler(slider:NSSlider)  {
        whiteBalance.tint = slider.floatValue/100
        //rawFile?.tint =  slider.floatValue
    }
   
    @objc func click(gesture:NSClickGestureRecognizer)  {
        if gesture.state == .began {
            Swift.print(" ... gesture ")
            filter.enabled = false
        }
        else if gesture.state == .ended {
            filter.enabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
             
        view.wantsLayer = true
        view.layer?.backgroundColor = self.bg.cgColor
        
        //filter.colorSpace = .lab
        
        view.addSubview(curvesContainer)
        view.addSubview(imageView)
        
        
        let press = NSPressGestureRecognizer(target: self, action: #selector(click(gesture:)))
        press.minimumPressDuration = 0.001
        imageView.addGestureRecognizer(press)
        
        curvesContainer.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().multipliedBy(0.33)
        }
        
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(curvesContainer.snp.right).offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        
        curvesContainer.addSubview(rgbCurveView)
        curvesContainer.addSubview(labCurveView)
        curvesContainer.addSubview(resultHistogramView)
        curvesContainer.addSubview(slider)
        curvesContainer.addSubview(tempSlider)
        curvesContainer.addSubview(tintSlider)
        
        view.addSubview(labHistogramView, positioned: NSWindow.OrderingMode.below, relativeTo: view)
        view.addSubview(rgbHistogramView, positioned: NSWindow.OrderingMode.below, relativeTo: view)
        
        self.labHistogramView.snp.makeConstraints { (make) in
            let x = labCurveView.padding.dX
            let y = labCurveView.padding.dY
            make.edges.equalTo(labCurveView).inset(NSEdgeInsetsMake(y, x+labCurveView.gridAxisWidth, y+labCurveView.gridAxisWidth, x))
        }

        self.rgbHistogramView.snp.makeConstraints { (make) in
            let x = rgbCurveView.padding.dX
            let y = rgbCurveView.padding.dY
            make.edges.equalTo(rgbCurveView).inset(NSEdgeInsetsMake(y, x+rgbCurveView.gridAxisWidth, y+rgbCurveView.gridAxisWidth, x))
        }
        
        curvesContainer.addSubview(biasSlider)
        
        rgbCurveView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            //make.bottom.equalToSuperview().multipliedBy(0.3)//.offset(-30)
            make.height.equalTo(200)
            make.right.equalToSuperview()
        }
        
        biasSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(rgbCurveView.snp.bottom).offset(10)
        }
        
        labCurveView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            //make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(200)
            make.top.equalTo(biasSlider.snp.bottom).offset(10)
            make.right.equalToSuperview()
        }
        
        resultHistogramView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            //make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(200)
            make.top.equalTo(labCurveView.snp.bottom).offset(10)
            make.right.equalToSuperview()
        }
        
        slider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(resultHistogramView.snp.bottom).offset(5)
        }
        
        tempSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(slider.snp.bottom).offset(10)
        }
        
        tintSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(tempSlider.snp.bottom).offset(5)
        }
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    public func saveCLut(to path: String, type:IMPCLut.LutType) {
        do {
            let lut = try lutFilter.clut?.convert(to: type)
            if type == .lut_2d {
                try lut?.write(to: path, using: .png)
            }
            else {
                try lut?.writeAsCube(to: path)
            }
        }
        catch let error {
            Swift.print("Export error: \(error)")
        }
        
    }

}
