//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//

extension Observable {
    final class Value {
        init(
            initialValue: Element,
            source sourceObservable: Observable
        ) {
            self.current = initialValue

            let sourceMulticast = Multicast()
            self.observable = sourceMulticast.observable

            sourceObservable
                .subscribe { [weak self] value in
                    self?.current = value
                    sourceMulticast.send(value)
                }
                .disposeWhenDealloc(self)
        }

        let observable: Observable

        private(set) var current: Element
    }
}

extension Observable.Value {
    convenience init<Wrapped>(source sourceObservable: Observable) where Element == Wrapped? {
        self.init(initialValue: nil, source: sourceObservable)
    }
}
