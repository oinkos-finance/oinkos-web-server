//
//  TransactionDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 13/02/25.
//

import Vapor

enum TransactionType: String, Codable {
    case unique, recurring
}

struct PostTransaction: Content, Validatable {
    var transactionType: TransactionType
    var title: String
    var value: Float
    var category: PaymentType

    // exclusive for unique transactions
    var transactionDate: Date?

    // exclusive for recurring transactions
    var recurrenceDay: Int8?
    var startingDate: Date?

    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("value", as: Float.self, is: .range(0...))
    }

    func toModel(user: User) throws -> any Transaction {
        switch self.transactionType {
        case .recurring:
            guard
                let recurrenceDay = self.recurrenceDay,
                let startingDate = self.startingDate
            else {
                throw Abort(.badRequest, reason: "Malformed syntax")
            }

            return RecurringTransaction(
                userId: try user.requireID(),
                title: self.title,
                value: self.value,
                category: self.category,
                recurrenceDay: recurrenceDay,
                startingDate: startingDate
            )
        case .unique:
            guard let transactionDate = self.transactionDate else {
                throw Abort(.badRequest, reason: "Malformed syntax")
            }

            return UniqueTransaction(
                userId: try user.requireID(),
                title: self.title,
                value: self.value,
                category: self.category,
                transactionDate: transactionDate
            )
        }
    }
}
