//
//  File.swift
//  
//
//  Created by Ernest Babayan on 30.07.2022.
//


final class Disposable {
    init(onDispose handler: @escaping () -> Void) { self.handler = handler  }

    private var handler: (() -> Void)?

    func dispose() {
        handler?()
        handler = nil
    }
}
