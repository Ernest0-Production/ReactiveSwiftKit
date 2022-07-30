//
//  File.swift
//  
//
//  Created by Ernest Babayan on 07.08.2022.
//

import Foundation

extension Observable {
    final class Completable {
        typealias CompletionObserver = () -> Void

        typealias Observer = (
            sendElement: Observable.Observer,
            sendCompletion: CompletionObserver
        )

        init(onSubscribe subscription: @escaping (Observer) -> Disposable) { self.subscription = subscription }

        private let subscription: (Observer) -> Disposable

        func subscribe(
            receiveElement: @escaping Observable.Observer,
            receiveCompletion: @escaping CompletionObserver
        ) -> Disposable {
            Disposable.single { handler in
                subscription((
                    sendElement: { element in
                        guard !handler.isDisposed() else { return }
                        receiveElement(element)
                    },
                    sendCompletion: handler.dispose
                ))
            }
        }
    }

    func complete(when shouldComplete: @escaping (Element) -> Bool) -> Completable {
        Completable { observer in
            self.subscribe { element in
                observer.sendElement(element)

                if shouldComplete(element) {
                    observer.sendCompletion()
                }
            }
        }
    }

    func asCompletable() -> Completable {
        Completable { observer in
            Disposable.composite([
                self.subscribe(receiveElement: observer.sendElement),
                Disposable(onDispose: observer.sendCompletion)
            ])
        }
    }
}
