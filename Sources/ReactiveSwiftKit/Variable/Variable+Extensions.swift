//
//  File.swift
//  
//
//  Created by Ernest Babayan on 07.08.2022.
//

import Foundation


extension Observable.Variable {
    convenience init<Wrapped>() where Element == Wrapped? {
        self.init(nil)
    }

    convenience init(_ value: Observable.Value) {
        self.init(value.current)

        value
            .observable
            .subscribe { [weak self] in self?.send($0) }
            .disposeWhenDealloc(self)
    }
}
