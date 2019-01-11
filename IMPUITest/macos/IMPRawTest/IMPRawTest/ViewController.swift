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

class ViewController: NSViewController, IMPCurvesViewDelegate, IMPHistogramViewDataSource {

    let histogramOpacity:CGFloat = 0.3
    
    var rawFile:IMPRawFile? {
        didSet{
            filter.source = rawFile
        }
    }
    
    var imagePath:String? {
        didSet{
            guard  let path = imagePath else {
                return
            }
            rawFile = IMPRawFile(context: filter.context, 
                                 rawFile: path, 
                                 scale:0.5, draft:true)
        }
    }
    
    let context = IMPContext()

    var colorRange = IMPHistogramRangeSolver()
    var avrgColor  = IMPHistogramDominantColorSolver()
    var adams      = IMPHistogramZonesSolver()
    
    lazy var resultHistogramAnalyzer:IMPHistogramAnalyzer = {
        var r = IMPHistogramAnalyzer(context: self.context)
        r.add(solver: self.colorRange){ (solver) in
            //NSLog(" range = \(self.colorRange.minimum, self.colorRange.maximum)")
        }
        r.add(solver: self.avrgColor){ (solver) in
            //NSLog(" average = \(self.avrgColor.color)")
        }
        r.add(solver: self.adams){ (solver) in
            /*NSLog(" adams.zones.steps   = \(self.adams.zones.steps)")
            NSLog(" adams.zones.balance = \(self.adams.zones.balance)")
            NSLog(" adams.zones.spots   = \(self.adams.zones.spots)")
            NSLog(" adams.zones.range   = \(self.adams.zones.range)")*/
        }
        return r
    }()
    
    lazy var resultHistogramView:IMPHistogramView = {
        var v = IMPHistogramView()
        v.backgroundColor = NSColor.clear
        v.dataSource = self
        return v
    }()
    
    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        
        f --> self.resultHistogramAnalyzer --> { (source) in
            DispatchQueue.main.async {
                //self.resultHistogramView.reload()
            }
        }
             
        f.addObserver(newSource: { (source) in
            Swift.print(" ### new source")
            self.filter.process()
        })
        
        f.addObserver(destinationUpdated: { (destination) in
            //Swift.print(" ### destination updated")
            //self.imageView.image = destination
        })
        
        //f.addObserver(dirty: self.dirtyObserver)
        
        return f
    }()
    
    
    private lazy var dirtyObserver:IMPFilter.FilterHandler = {
        let handler:IMPFilter.FilterHandler = { (filter, source, destination) in
            Swift.print(" ### dirtyObserver updated")
            //self.filter.process()
        } 
        return handler
    }()
    
    lazy var rgbInfo = IMPCurveViewInfo.rgb()
    
    func histogram(view: IMPHistogramView) -> IMPHistogram {
        return resultHistogramAnalyzer.histogram
    }
    
    func histogram(view: IMPHistogramView, clampColorForChannel index: Int) -> NSColor {
        return NSColor.clear
    }
    
    func histogram(view: IMPHistogramView, clampEdgesForChannel index: Int) -> (left: CGFloat, right: CGFloat) {
        return (0,1)
    }
    
    func histogram(view: IMPHistogramView, fillColorForChannel index: Int) -> NSColor {
        return NSColor.gray //rgbInfo[index].color
    }
    
    func histogram(view: IMPHistogramView, shouldVisibleForChannel index: Int) -> Bool {
        return index == 0
    }
    
    lazy var evLabel: NSTextField = NSTextField(labelWithString: "EV")
    lazy var biasLabel: NSTextField = NSTextField(labelWithString: "Bias")
    lazy var boostLabel: NSTextField = NSTextField(labelWithString: "Boost")
    lazy var shadowBoostLabel: NSTextField = NSTextField(labelWithString: "Shadow Boost")
    
    lazy var evSlider:NSSlider = NSSlider(value: 0, minValue: -5, maxValue: 5, target: self, action: #selector(evHandler(sender:)))
    lazy var biasSlider:NSSlider = NSSlider(value: 0, minValue: -100, maxValue: 100, target: self, action: #selector(biasHanlder(sender:)))
    lazy var boostSlider:NSSlider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: self, action: #selector(boostHandler(sender:)))
    lazy var shadowBoostSlider:NSSlider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: self, action: #selector(shadowBoostHandler(sender:)))

    lazy var sharpeningCheckBox: NSButton = NSButton(checkboxWithTitle: "Sharpening", target: self, action: #selector(sharpeningHandler(sender:)))
    
    func updateEvLabel() {
        evLabel.stringValue = "EV [\(String(describing: self.evSlider.floatValue))]";
    }
    
    func updateBiasLabel() {
        biasLabel.stringValue = "Bias [\(String(describing: self.biasSlider.floatValue))]";
    }

    func updateBoostLabel() {
        boostLabel.stringValue = "Boost [\(String(describing: self.boostSlider.floatValue))]";
    }
    
    func updateShadowBoostLabel() {
        shadowBoostLabel.stringValue = "Shadow Boost [\(String(describing: self.shadowBoostSlider.floatValue))]";
    }
    
    @objc func evHandler(sender:NSSlider)  {
        rawFile?.ev = sender.floatValue
        updateEvLabel()
    }
    
    @objc func biasHanlder(sender:NSSlider)  {
        rawFile?.bias = sender.floatValue
        updateBiasLabel()
    }
    
    @objc func boostHandler(sender:NSSlider)  {
        rawFile?.boost = sender.floatValue
        updateBoostLabel()
    }
    
    @objc func shadowBoostHandler(sender:NSSlider)  {
        rawFile?.boostShadow = sender.floatValue
        updateShadowBoostLabel()
    }
    
    @objc func sharpeningHandler(sender:NSButton)  {
        rawFile?.enableSharpening = sender.state.rawValue == 1;
    }
    
    lazy var curvesContainer:NSView = NSView()
    
    lazy var imageView:IMPFilterView = {
        
        let v = IMPFilterView(frame: self.view.bounds)
        
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.clear.cgColor
        v.filter = self.filter
        
        
        return v
    }()

    let bg = NSColor(deviceWhite: 0.1, alpha: 1)
    
    func setupSlider(_ slider:NSSlider) {
        slider.numberOfTickMarks = 21;
        slider.allowsTickMarkValuesOnly = true;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
             
        view.wantsLayer = true
        
        view.addSubview(curvesContainer)
        view.addSubview(imageView)
        
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
        
        curvesContainer.addSubview(resultHistogramView)
        
        setupSlider(evSlider)
        setupSlider(biasSlider)
        setupSlider(boostSlider)
        setupSlider(shadowBoostSlider)
        
        updateEvLabel()
        updateBiasLabel()
        updateBoostLabel()
        updateShadowBoostLabel()
        
        curvesContainer.addSubview(evLabel)
        curvesContainer.addSubview(biasLabel)
        curvesContainer.addSubview(boostLabel)
        curvesContainer.addSubview(shadowBoostLabel)
        
        curvesContainer.addSubview(evSlider)
        curvesContainer.addSubview(biasSlider)
        curvesContainer.addSubview(boostSlider)
        curvesContainer.addSubview(shadowBoostSlider)
        
        //curvesContainer.addSubview(sharpeningCheckBox)
        
        resultHistogramView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(200)
            make.top.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        // EV
        
        evLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(resultHistogramView.snp.bottom).offset(10)
        }
        
        evSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(evLabel.snp.bottom)
        }
        
        // Bias
        
        biasLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(evSlider.snp.bottom).offset(10)
        }
        
        biasSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(biasLabel.snp.bottom)
        }
        
        // Boost
        
        boostLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(biasSlider.snp.bottom).offset(10)
        }
        
        boostSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(boostLabel.snp.bottom)
        }
        
        // Shadow Boost
        
        shadowBoostLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(boostSlider.snp.bottom).offset(10)
        }
        
        shadowBoostSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(shadowBoostLabel.snp.bottom)
        }
        
        // Sharpening
        
//        sharpeningCheckBox.snp.makeConstraints { (make) in
//            make.left.equalToSuperview()
//            make.right.equalToSuperview()
//            make.top.equalTo(shadowBoostSlider.snp.bottom).offset(10)
//        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}
