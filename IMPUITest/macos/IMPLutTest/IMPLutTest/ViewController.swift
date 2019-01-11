//
//  ViewController.swift
//  IMPLutTest
//
//  Created by denis svinarchuk on 25.08.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Cocoa
import IMProcessing

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let export = "/Users/denn/Desktop/zero-test.cube"
        let exportim = "/Users/denn/Desktop/zero-test.png"
        do{
            let zeroLut = try IMPCLut(context: IMPContext(), lutType: .lut_2d, lutSize: 64, format: .float, title: "Zero Test")
            
            try zeroLut.write(to: exportim, using: .png)

            //try zeroLut.writeAsCube(to: export)
            
        }
        catch let error {
            Swift.print("error: \(error): \(export)")
        }
        
        if var file = Bundle.main.path(forResource: "K64PW", ofType: "cube"){
            
            Swift.print("file = \(file)");
            
            do {
                let context = IMPContext();
                
                let url = URL(fileURLWithPath: file)
                let lutK64PW = try IMPCLut(context: context, cube: url)
                
                file = "/Users/denn/Desktop/K64PW.cube"
                try lutK64PW.write(cube: file)
                
                let pnglut = try lutK64PW.convert(to: .lut_2d, lutSize: 64)
                file = "/Users/denn/Desktop/K64PW.png"
                
                try pnglut.write(to: file, using: .png)

                let checkLut = try IMPCLut(context: context, haldImage: file)
                
                file = "/Users/denn/Desktop/K64PW-checked.png"
                try checkLut.write(to: file, using: .png)
                
                //
                // png Hald test
                //
                if let lookup = Bundle.main.path(forResource: "lookup_miss_etikate", ofType: "png"){
                    file = lookup
                    let lookupLut2d = try IMPCLut(context: context, haldImage: lookup)
                    
                    file = "/Users/denn/Desktop/lookup_miss_etikate.png"
                    try lookupLut2d.write(to: file, using: .png)
                    
                    let lookupLut3d = try lookupLut2d.convert(to: .lut_3d, lutSize: 64, format: .float, title: "lookup_miss_etikate")
                    
                    file = "/Users/denn/Desktop/lookup_miss_etikate.cube"
                    try lookupLut3d.write(cube: file)
                    
                    file = "/Users/denn/Desktop/lookup_miss_etikate-checked.png"
                    
                    let lookupLut2dCheck = try lookupLut3d.convert(to: .lut_2d, lutSize: 64, format: .float, title: "lookup_miss_etikate-checked")

                    try lookupLut2dCheck.write(to: file, using: .png)
                    
                    let lookupLut1d = try lookupLut2d.convert(to: .lut_1d, lutSize: 1024, format: .float)
                    
                    file = "/Users/denn/Desktop/lookup_miss_etikate-checked-1D.cube"
                    try lookupLut1d.write(cube: file)

                }
                
                //
                // 1D conversion -->
                //
                
                if let file1d = Bundle.main.path(forResource: "DaV1024_1D", ofType: "cube"){
                    file = file1d
                    let lookupLut1d = try IMPCLut(context: context, cube: file)
                    
                    let lookupLut3d = try lookupLut1d.convert(to: .lut_3d, lutSize: 32, format: .float)

                    file = "/Users/denn/Desktop/DaV1024_1D-3D.cube"
                    try lookupLut3d.write(cube: file)
                 
                    let lookupLut2d = try lookupLut1d.convert(to: .lut_2d, lutSize: 64, format: .float)

                    file = "/Users/denn/Desktop/DaV1024_1D-2D.png"
                    try lookupLut2d.write(to: file, using: .png)
                }
                
                //
                // 3D -- >
                //
                
                let lutK64PW1D = try lutK64PW.convert(to: .lut_1d, lutSize: 1024)
                file = "/Users/denn/Desktop/lutK64PW1D-1D.cube"
                try lutK64PW1D.write(cube: file)
                
                let lutK64PW2D = try lutK64PW1D.convert(to: .lut_2d, lutSize: 64, format: .float)
                file = "/Users/denn/Desktop/lutK64PW1D-1D-2D.png"
                try lutK64PW2D.write(to: file, using: .png)

            }
            catch let error {
                Swift.print("error: \(error): \(file)")
            }
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

