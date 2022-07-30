//
//  File.swift
//  
//
//  Created by Ernest Babayan on 21.08.2022.
//

import Foundation


extension Observable.Completable {
    static var completed: Observable.Completable {
        Observable.Completable { observer in
            observer.sendCompletion()
            return Disposable.empty
        }
    }

    static var never: Observable.Completable {
        Observable.Completable { _ in
            Disposable.empty
        }
    }

    func elementObservable() -> Observable<Element> {
        Observable { observer in
            self.subscribe(
                receiveElement: observer,
                receiveCompletion: {}
            )
        }
    }

    func completionObservable() -> Observable<Void> {
        Observable<Void> { observer in
            self.subscribe(
                receiveElement: { _ in },
                receiveCompletion: { observer(()) }
            )
        }
    }

    func mapElementObservable<NewElement>(
        _ transform: @escaping (Observable) -> Observable<NewElement>
    ) -> Observable<NewElement>.Completable {
        Observable<NewElement>.Completable { observer in
            let multicast = Observable.Multicast()

            return Disposable.composite([
                self.subscribe(
                    receiveElement: multicast.send,
                    receiveCompletion: observer.sendCompletion
                ),

                transform(multicast.observable).subscribe(receiveElement: observer.sendElement)
            ])
        }
    }
}

extension Observable {
    func concat<FlattenCompletableElement>() -> Observable<FlattenCompletableElement> where Element == Observable<FlattenCompletableElement>.Completable {
        Observable<FlattenCompletableElement> { observer in
            typealias Completable = Observable<FlattenCompletableElement>.Completable
            typealias CompletableSubscription = (Completable.Observer) -> Void

            var pendingCompletables: [Completable] = []
            let currentCompletable = Multicast()

            let currentCompletableDisposable = currentCompletable.observable
                .map({ completable -> Observable<CompletableSubscription> in
                    Observable<CompletableSubscription> { singleSubscription in
                        completable.subscribe(
                            receiveElement: { element in
                                singleSubscription { completableObserver in
                                    completableObserver.sendElement(element)
                                }
                            },
                            receiveCompletion: {
                                singleSubscription { completableObserver in
                                    completableObserver.sendCompletion()
                                }
                            }
                        )
                    }
                })
                .switchToLatest()
                .subscribe { (completableSubscription: CompletableSubscription) in
                    completableSubscription((
                        sendElement: observer,
                        sendCompletion: {
                            pendingCompletables.removeFirst()

                            if let nextCompletable = pendingCompletables.first {
                                currentCompletable.send(nextCompletable)
                            }
                        }
                    ))
                }

            let upstreamDisposable = self.subscribe { completable in
                if pendingCompletables.isEmpty {
                    currentCompletable.send(completable)
                }

                pendingCompletables.append(completable)
            }

            return Disposable.composite([
                upstreamDisposable,
                currentCompletableDisposable,
            ])
        }
    }

    static func concat(_ completables: [Observable.Completable]) -> Observable.Completable {
        Completable { observer in
            let completionCompletable = Completable {
                $0.sendCompletion()

                observer.sendCompletion()

                return Disposable.empty
            }

            return Observable<Completable>.just(completables + [completionCompletable])
                .concat()
                .subscribe(receiveElement: observer.sendElement)
        }
    }
}

