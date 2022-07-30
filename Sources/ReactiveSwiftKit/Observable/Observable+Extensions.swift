//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//

import Foundation


extension Observable {
    // MARK: - Static Events
    
    func start(with element: Element) -> Observable {
        Observable { observer in
            observer(element)
            return self.subscribe(receiveElement: observer)
        }
    }

    func start(with element: @escaping () -> Element) -> Observable {
        Observable { observer in
            observer(element())
            return self.subscribe(receiveElement: observer)
        }
    }

    func replay(bufferSize: Int = 1) -> Observable<Element> {
        var buffer = [Element]()
        buffer.reserveCapacity(bufferSize + 1)

        return Observable { observer in
            for cachedElement in buffer {
                observer(cachedElement)
            }

            return self.subscribe { element in
                buffer.append(element)
                buffer = buffer.suffix(bufferSize)
                observer(element)
            }
        }
    }

    // MARK: - Transformation

    func map<TransformedElement>(
        _ transform: @escaping (Element) -> TransformedElement
    ) -> Observable<TransformedElement> {
        Observable<TransformedElement> { observer in
            self.subscribe { element in
                let transformedElement = transform(element)
                observer(transformedElement)
            }
        }
    }

    func filterNil<WrappedElement>() -> Observable<WrappedElement> where Element == WrappedElement? {
        Observable<WrappedElement> { observer in
            self.subscribe { element in
                if let element {
                    observer(element)
                }
            }
        }
    }

    func filterMap<TransformedElement>(
        _ transform: @escaping (Element) -> TransformedElement?
    ) -> Observable<TransformedElement> {
        Observable<TransformedElement> { observer in
            self.subscribe { element in
                if let transformedElement = transform(element) {
                    observer(transformedElement)
                }
            }
        }
    }

    // MARK: - Enumeration

    func enumerated() -> Observable<(index: Int, element: Element)> {
        Observable<(index: Int, element: Element)> { observer in
            var currentIndex = 0

            return self.subscribe { element in
                defer { currentIndex += 1 }

                observer((currentIndex, element))
            }
        }
    }

    // MARK: - Filter

    func filter(
        _ shouldInclude: @escaping (Element) -> Bool
    ) -> Observable {
        Observable { observer in
            self.subscribe { element in
                if shouldInclude(element) {
                    observer(element)
                }
            }
        }
    }

    func removeDuplicates(
        compatator isDublicate: @escaping (Element, Element) -> Bool
    ) -> Observable {
        Observable { observer in
            var lastElement: Element?

            return self.subscribe { element in
                defer { lastElement = element }

                guard let lastElement else {
                    observer(element)
                    return
                }

                guard !isDublicate(lastElement, element) else {
                    return
                }

                observer(element)
            }
        }
    }

    func removeDublicates<Value: Equatable>(comparing equatableValue: @escaping (Element) -> Value) -> Observable {
        removeDuplicates(compatator: {
            equatableValue($0) == equatableValue($1)
        })
    }

    func removeDuplicates<Value: Equatable>(by keyPath: KeyPath<Element, Value>) -> Observable {
        removeDuplicates(compatator: {
            $0[keyPath: keyPath] == $1[keyPath: keyPath]
        })
    }

    func removeDublicates() -> Observable where Element: Equatable {
        removeDuplicates(by: \.self)
    }

    func skipFirst() -> Observable {
        skip(1)
    }

    func skip(_ elementsCount: Int) -> Observable {
        Observable { observer in
            var remainingCount = elementsCount

            return self.subscribe { element in
                guard remainingCount == 0 else {
                    remainingCount -= 1
                    return
                }

                observer(element)
            }
        }
    }

    func first(disposeOnFinish: Bool = false) -> Observable {
        prefix(1, disposeOnFinish: disposeOnFinish)
    }

    func prefix(_ elementsCount: Int, disposeOnFinish: Bool = false) -> Observable {
        Observable { observer in
            var remainingCount = elementsCount
            let deferredDisposable = Disposable.Deferred()

            return self.subscribe { element in
                if remainingCount == 0 { return }
                remainingCount -= 1

                observer(element)

                if remainingCount == 0 && disposeOnFinish {
                    deferredDisposable.dispose()
                }
            }
            .embed(in: deferredDisposable)
        }
    }

    // MARK: - Dispatch

    func observe(on queue: DispatchQueue) -> Observable {
        Observable { observer in
            let deferredDisposable = Disposable.Deferred()

            queue.async {
                self.subscribe(receiveElement: observer).embed(in: deferredDisposable)
            }

            return deferredDisposable.asDisposable()
        }
    }

    func subscribe(on queue: DispatchQueue) -> Observable {
        Observable { observer in
            self.subscribe { element in
                queue.async {
                    observer(element)
                }
            }
        }
    }

    // MARK: - Compositite

    func switchToLatest<FlattenElement>() -> Observable<FlattenElement> where Element == Observable<FlattenElement> {
        Observable<FlattenElement> { observer in
            var lastDisposable: Disposable?

            let upstreamDisposable = self.subscribe { innerObservable in
                lastDisposable?.dispose()
                lastDisposable = innerObservable.subscribe(receiveElement: observer)
            }

            return Disposable {
                upstreamDisposable.dispose()
                lastDisposable?.dispose()
            }
        }
    }

    func merge<FlattenElement>() -> Observable<FlattenElement> where Element == Observable<FlattenElement> {
        Observable<FlattenElement> { observer in
            var disposables: [Disposable] = []

            let upstreamDisposable = self.subscribe { elementObservable in
                let newDisposable = elementObservable.subscribe(receiveElement: observer)
                disposables.append(newDisposable)
            }

            disposables.append(upstreamDisposable)

            return Disposable {
                Disposable.composite(disposables).dispose()
            }
        }
    }

    static func merge(_ observables: [Observable]) -> Observable {
        Observable<Observable>.sequence(observables).merge()
    }

    // MARK: Creation

    static func just(_ element: Element) -> Observable {
        Observable.sequence([element])
    }

    static func sequence(_ elements: any Sequence<Element>) -> Observable {
        Observable { observer in
            elements.forEach(observer)
            return Disposable.empty
        }
    }

    static var empty: Observable {
        Observable { _ in
            Disposable.empty
        }
    }

    static func deferred(_ observable: @escaping () -> Observable) -> Observable {
        Observable { observer in
            observable().subscribe(receiveElement: observer)
        }
    }

    func retain(_ object: AnyObject) -> Observable {
        Observable { observer in
            self.subscribe {
                let _ = object
                observer($0)
            }
        }
    }

    // MARK: - Side Effects

    func beforeReceiveElement(_ perform: @escaping (Element) -> Void) -> Observable {
        Observable { observer in
            self.subscribe { element in
                perform(element)
                observer(element)
            }
        }
    }

    func afterReceiveElement(_ perform: @escaping (Element) -> Void) -> Observable {
        Observable { observer in
            self.subscribe { element in
                observer(element)
                perform(element)
            }
        }
    }

    func beforeSubscribe(_ perform: @escaping () -> Void) -> Observable {
        Observable { observer in
            perform()
            return self.subscribe(receiveElement: observer)
        }
    }

    func afterSubscribe(_ perform: @escaping () -> Void) -> Observable {
        Observable { observer in
            let disposable = self.subscribe(receiveElement: observer)
            perform()
            return disposable
        }
    }

    func beforeDispose(_ perform: @escaping () -> Void) -> Observable {
        Observable { observer in
            let sourceDisposable = self.subscribe(receiveElement: observer)

            return Disposable {
                perform()
                sourceDisposable.dispose()
            }
        }
    }

    func afterDispose(_ perform: @escaping () -> Void) -> Observable {
        Observable { observer in
            let sourceDisposable = self.subscribe(receiveElement: observer)

            return Disposable {
                sourceDisposable.dispose()
                perform()
            }
        }
    }

 }
