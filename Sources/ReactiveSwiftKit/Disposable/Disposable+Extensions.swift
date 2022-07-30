//
//  File.swift
//  
//
//  Created by Ernest Babayan on 07.08.2022.
//

import Foundation

// MARK: - Composite

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

// MARK: - Memory

extension Disposable {
    @discardableResult
    func disposeWhenDealloc(_ owner: AnyObject) -> Disposable {
        whenDealloc(owner, dispose)
        return self
    }
}

// MARK: - Deferred

extension Disposable {
    final class Deferred {
        fileprivate var decoratee: Disposable?

        private(set) var isDisposed = false

        var isInitialized: Bool {
            decoratee != nil
        }

        func dispose() {
            guard !isDisposed else { return }
            isDisposed = true
            decoratee?.dispose()
            decoratee = nil
        }

        func asDisposable() -> Disposable {
            Disposable(onDispose: dispose)
        }
    }
}

extension Disposable {
    @discardableResult
    func embed(in deferred: Deferred) -> Disposable {
        if deferred.isDisposed {
            dispose()
            return Disposable.empty
        } else {
            deferred.decoratee = self
            return deferred.asDisposable()
        }
    }
}
