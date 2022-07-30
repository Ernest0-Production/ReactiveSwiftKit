//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.10.2023.
//

import Foundation


extension Observable {
    final class Sender {
        init() {
            let multicast = Observable { [weak self] observer in
                self?.observer = observer

                return Disposable.empty
            }
            .multicast()

            self.observable = multicast.observable
            multicast.start()
        }

        private var observer: Observable.Observer = { _ in }

        private(set) var observable: Observable!

        func send(_ element: Element) {
            observer(element)
        }
    }
}
