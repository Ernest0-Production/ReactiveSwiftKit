//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//

import Foundation


func whenDealloc(_ object: AnyObject, _ completion: @escaping () -> Void) {
    DeallocObserver(object, completion)
}

private final class DeallocObserver {
    private let completion: () -> Void

    @discardableResult
    fileprivate init(
        _ object: AnyObject,
        _ completion: @escaping () -> Void
    ) {
        self.completion = completion
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        objc_setAssociatedObject(object, pointer, self, .OBJC_ASSOCIATION_RETAIN)
    }

    deinit { completion() }
}
