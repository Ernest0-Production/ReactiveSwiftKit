//
//  File.swift
//  
//
//  Created by Ernest Babayan on 30.07.2022.
//

import Foundation


extension Observable {
    final class Multicast {
        private var observers: [UUID: Observer] = [:]

        private(set) lazy var observable = Observable { [weak self] observer in
            let uuid = UUID()

            self?.observers[uuid] = observer

            return Disposable { self?.observers[uuid] = nil }
        }

        func send(_ element: Element) {
            for observer in observers.values {
                observer(element)
            }
        }
    }
}
