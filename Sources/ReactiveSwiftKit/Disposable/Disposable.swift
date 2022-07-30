//
//  File.swift
//  
//
//  Created by Ernest Babayan on 30.07.2022.
//


final class Disposable {
    init(onDispose: @escaping () -> Void) { self.dispose = onDispose }

    let dispose: () -> Void
}
