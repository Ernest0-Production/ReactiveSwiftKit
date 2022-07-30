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
            let valueMulticast = Multicast()

            value = Value(
                initialValue: initialValue,
                source: valueMulticast.observable
            )

            send = valueMulticast.send
        }

        convenience init(wrappedValue: Element) {
            self.init(wrappedValue)
        }

        let value: Value

        let send: (Element) -> Void

        var wrappedValue: Element {
            get { value.current }
            set { send(newValue) }
        }

        var projectedValue: Observable {
            value.observable
        }
    }
}
