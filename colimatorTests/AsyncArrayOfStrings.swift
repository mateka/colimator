//
//  AsyncArrayOfStrings.swift
//  colimatorTests
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import Foundation


struct AsyncArrayOfStrings: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = String

    let contents: [Element]
    var current: Int = 0

    init(fromArray elements: [Element]) {
        self.contents = elements
    }

    mutating func next() async -> Element? {
        if self.current >= self.contents.count {
            return nil
        }

        let elem = self.contents[self.current]
        self.current += 1
        return elem
    }

    func makeAsyncIterator() -> AsyncArrayOfStrings {
        self
    }
}
