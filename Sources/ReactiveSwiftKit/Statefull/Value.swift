//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//

extension Observable {
    @propertyWrapper
    final class Value {
        init(
            initialValue: Element,
            source sourceObservable: Observable
        ) {
            self.current = initialValue

            let sourceMulticast = sourceObservable
                .beforeReceiveElement { [weak self] element in
                    self?.current = element
                }
                .start(with: initialValue)
                .replay()
                .multicast()

            self.observable = sourceMulticast.observable

            sourceMulticast.start()
        }

        private(set) var observable: Observable!

        private(set) var current: Element

        var wrappedValue: Element {
            current
        }

        var projectedValue: Observable {
            observable
        }
    }
}

extension Observable.Value {
    convenience init<Wrapped>(source sourceObservable: Observable) where Element == Wrapped? {
        self.init(initialValue: nil, source: sourceObservable)
    }
}
