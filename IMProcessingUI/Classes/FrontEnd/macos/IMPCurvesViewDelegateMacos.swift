//
//  IMPCurvesViewDelegate.swift
//  IMPCurveTest
//
//  Created by denis svinarchuk on 18.06.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

#if os(OSX)

public protocol IMPCurvesViewDelegate {
    func curvesView(_ view:IMPCurvesView, didEndUpdate info:IMPCurveViewInfo)
    func curvesView(_ view:IMPCurvesView, didSelect info:IMPCurveViewInfo)
    func curvesView(_ view:IMPCurvesView, didDeselect info:IMPCurveViewInfo)
    func curvesView(_ view:IMPCurvesView, didHighlight info:IMPCurveViewInfo)
    func curvesView(_ view:IMPCurvesView, didUpdate info:IMPCurveViewInfo)
    func curvesView(_ view:IMPCurvesView, didRemove info:IMPCurveViewInfo, points: [float2])
    func curvesView(_ view:IMPCurvesView, didAdd info:IMPCurveViewInfo, points: [float2])
}

public extension IMPCurvesViewDelegate {
    func curvesView(_ view:IMPCurvesView, didEndUpdate info:IMPCurveViewInfo) {}
    func curvesView(_ view:IMPCurvesView, didSelect info:IMPCurveViewInfo) {}
    func curvesView(_ view:IMPCurvesView, didDeselect info:IMPCurveViewInfo) {}
    func curvesView(_ view:IMPCurvesView, didHighlight info:IMPCurveViewInfo) {}
    func curvesView(_ view:IMPCurvesView, didUpdate info:IMPCurveViewInfo) {}
    func curvesView(_ view:IMPCurvesView, didRemove info:IMPCurveViewInfo, points: [float2]) {}
    func curvesView(_ view:IMPCurvesView, didAdd info:IMPCurveViewInfo, points: [float2]) {}
}

#endif
