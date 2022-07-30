//
//  File.swift
//  
//
//  Created by Ernest Babayan on 07.08.2022.
//

import Foundation


extension Disposable {
    static var empty: Disposable {
        Disposable(onDispose: {})
    }

    static func composite(_ disposables: [Disposable]) -> Disposable {
        Disposable {
            for disposable in disposables {
                disposable.dispose()
            }
        }
    }
}

extension Optional where Wrapped == Disposable {
    func unwrapped() -> Disposable {
        Disposable { self?.dispose() }
    }
}

extension Disposable {
    @discardableResult
    func disposeWhenDealloc(_ owner: AnyObject) -> Disposable {
        whenDealloc(owner, dispose)
        return self
    }
}

extension Disposable {
    final class Single {
        private var source: Disposable?
        private var isDisposed: Bool {
            source == nil
        }

        typealias Handler = (
            dispose: () -> Void,
            isDisposed: () -> Bool
        )

        init(decoratee: (Handler) -> Disposable) {
            let handler: Handler = (
                dispose: { [weak self] in self?.dispose() },
                isDisposed: { [weak self] in self?.isDisposed ?? true }
            )

            source = decoratee(handler)
        }

        func dispose() {
            source?.dispose()
            source = nil
        }

        func asDisposable() -> Disposable {
            Disposable(onDispose: dispose)
        }
    }

    static func single(_ decoratee: (Single.Handler) -> Disposable) -> Disposable {
        Single(decoratee: decoratee).asDisposable()
    }
}
