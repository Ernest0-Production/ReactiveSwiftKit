//
//  File.swift
//  
//
//  Created by Ernest Babayan on 30.07.2022.
//

import Foundation


extension Observable {
    final class Multicast {
        init(source: Observable<Element>) {
            self.source = source
        }

        private let source: Observable
        private var sourceDisposable: Disposable?

        private var observers: [UUID: Observer] = [:]

        private(set) lazy var observable = Observable { observer in
            let uuid = UUID()

            self.observers[uuid] = observer

            return Disposable { [weak self] in self?.observers[uuid] = nil }
        }

        @discardableResult
        func start() -> Self {
            if sourceDisposable != nil { return self }

            sourceDisposable = source.subscribe { element in
                for observer in self.observers.values {
                    observer(element)
                }
            }

            return self
        }

        @discardableResult
        func stop() -> Self {
            sourceDisposable?.dispose()
            return self
        }
    }
}

extension Observable {
    func multicast() -> Multicast {
        Multicast(source: self)
    }
}


extension Observable.Multicast {
    @discardableResult
    func restart() -> Self {
        stop()
        start()
        return self
    }

    func startOnSubscribe() -> Observable.Multicast {
        let multicast = Observable.Multicast(source: Observable { observer in
            self.start()
            return self.observable.subscribe(receiveElement: observer)
        })

        return multicast
    }

//    func stopWhenAllUnsubscribes() -> Observable.Multicast2 {
//        let multicast = Observable.Multicast2(source: Observable { observer in
//            self.start()
//            return self.observable.subscribe(receiveElement: observer)
//        })
//
//        return multicast
//    }
}
