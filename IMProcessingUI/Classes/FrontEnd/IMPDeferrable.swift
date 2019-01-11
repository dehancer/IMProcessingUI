//
//  IMPDeferrable.swift
//  Pods
//
//  Created by Denis Svinarchuk on 28/06/2017.
//
//

import Foundation
import IMProcessing

private func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
                                 .OBJC_ASSOCIATION_RETAIN)
        return associated
}

private func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
    objc_setAssociatedObject(base, key, value,
                             .OBJC_ASSOCIATION_RETAIN)
}

public protocol IMPDeferrable {}

public class IMPDeferrableClosure:NSObject {

    public var delay:TimeInterval = NSEvent.keyRepeatInterval/2
    
    public var block: (()->Void)?  = nil {
        didSet{
            DispatchQueue.main.async(group: nil, qos: .userInteractive, flags: .detached) {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.execute), object: nil)
                self.perform(#selector(self.execute), with: nil, afterDelay: self.delay, inModes: [RunLoop.Mode.common, RunLoop.Mode.default])
            }
        }
    }
    
    @objc func execute()  {
        DispatchQueue.main.async {
            self.block?()            
        }
    }
}

private var __transactionClosure:UInt8 = 0

public extension IMPDeferrable {
    public var deferrable: IMPDeferrableClosure {
        get {
            return associatedObject(base: self as AnyObject, key: &__transactionClosure) {
                return IMPDeferrableClosure()
            }
        }
        set {
            associateObject(base: self as AnyObject, key: &__transactionClosure, value: newValue)
        }
    }
}
