//
//  File.swift
//  
//
//  Created by Ernest Babayan on 31.07.2022.
//


extension Observable {
    @propertyWrapper
    final class Variable {
        init(_ initialValue: Element) {
            self.sender = Sender()

            value = Value(
                initialValue: initialValue,
                source: sender.observable
            )
        }

        private let sender: Sender

        let value: Value

        func set(_ value: Element) {
            sender.send(value)
        }

        var wrappedValue: Element {
            get { value.current }
            set { set(newValue) }
        }

        var projectedValue: Observable {
            value.observable
        }
    }
}

extension Observable.Variable {
    convenience init<Wrapped>() where Element == Wrapped? {
        self.init(nil)
    }
}
