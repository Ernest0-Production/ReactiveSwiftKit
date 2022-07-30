//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//

import Foundation


extension Observable {
    func start(with element: Element) -> Observable {
        Observable { observer in
            observer(element)
            return self.subscribe(receiveElement: observer)
        }
    }

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

    func filterNil<Wrapped>() -> Observable<Wrapped> where Element == Wrapped? {
        Observable<Wrapped> { observer in
            self.subscribe { element in
                if let element = element {
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

    func enumerated() -> Observable<(index: Int, element: Element)> {
        Observable<(index: Int, element: Element)> { observer in
            var currentIndex = 0

            return self.subscribe { element in
                defer { currentIndex += 1 }

                observer((currentIndex, element))
            }
        }
    }

    func removeDublicates(
        compatator isDublicate: @escaping (Element, Element) -> Bool
    ) -> Observable {
        Observable { observer in
            var lastElement: Element?

            return self.subscribe { element in
                defer { lastElement = element }

                guard let lastElement = lastElement else {
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
        removeDublicates(compatator: {
            equatableValue($0) == equatableValue($1)
        })
    }

    func removeDublicates<Value: Equatable>(by keyPath: KeyPath<Element, Value>) -> Observable {
        removeDublicates(compatator: {
            $0[keyPath: keyPath] == $1[keyPath: keyPath]
        })
    }

    func removeDublicates() -> Observable where Element: Equatable {
        removeDublicates(by: \.self)
    }

    func observe(on queue: DispatchQueue) -> Observable {
        Observable { observer in
            var disposable: Disposable?
            var isDisposed = false

            queue.async {
                guard !isDisposed else { return }

                disposable = self.subscribe(receiveElement: observer)
            }

            return Disposable {
                isDisposed = true
                disposable?.dispose()
            }
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

    func first() -> Observable {
        prefix(1)
    }

    func prefix(_ elementsCount: Int) -> Observable {
        Observable { observer in
            var remainingCount = elementsCount

            return Disposable.single { handler in
                self.subscribe { element in
                    guard !handler.isDisposed() else { return }

                    observer(element)

                    remainingCount -= 1

                    if remainingCount == 0 {
                        handler.dispose()
                    }
                }
            }
        }
    }

    func switchToLatest<FlattenElement>() -> Observable<FlattenElement> where Element == Observable<FlattenElement> {
        Observable<FlattenElement> { observer in
            var lastDisposable: Disposable?

            let upstreamDisposable = self.subscribe { elementObservable in
                lastDisposable?.dispose()

                lastDisposable = elementObservable.subscribe(receiveElement: observer)
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
        Observable<Observable>.just(observables).merge()
    }

    static func just(_ element: Element) -> Observable {
        Observable.just([element])
    }

    static func just(_ elements: [Element]) -> Observable {
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
            Disposable.composite([
                Disposable(onDispose: perform),
                self.subscribe(receiveElement: observer)
            ])
        }
    }

    func afterDispose(_ perform: @escaping () -> Void) -> Observable {
        Observable { observer in
            Disposable.composite([
                self.subscribe(receiveElement: observer),
                Disposable(onDispose: perform)
            ])
        }
    }

    func retry<Success, Failure: Error>(count: Int = 1) -> Observable<Success> where Element == Result<Success, Failure> {
        Observable<Success> { observer in
            let retryObserver = Observable<Void>.Multicast()
            var remainingCount = count

            return retryObserver.observable
                .start(with: ())
                .map { self }
                .switchToLatest()
                .subscribe { result in
                    switch result {
                    case let .success(value):
                        observer(value)
                    case .failure:
                        if remainingCount > 0 {
                            remainingCount -= 1
                            retryObserver.send(())
                        }

                    }
                }
        }
    }
 }
