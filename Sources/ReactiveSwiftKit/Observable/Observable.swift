//
//  File.swift
//  
//
//  Created by Ernest Babayan on 30.07.2022.
//


final class Observable<Element> {
    typealias Observer = (Element) -> Void
    typealias Subscription = (@escaping Observer) -> Disposable

    init(onSubscribe subscription: @escaping Subscription) { self.subscription = subscription }

    private let subscription: (@escaping Observer) -> Disposable

    func subscribe(receiveElement: @escaping Observer = { _ in }) -> Disposable {
        subscription(receiveElement)
    }
}
