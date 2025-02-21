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

struct GetTransaction: Content {
    var onlyInclude: TransactionType?
    var category: String?
    var paymentType: PaymentType?
    var startingDate: Date
    var endingDate: Date
    
    init(include: TransactionType? = nil, category: String? = nil, paymentType: PaymentType? = nil, startingDate: Date, endingDate: Date) {
        self.onlyInclude = include
        self.category = category
        self.paymentType = paymentType
        self.startingDate = startingDate
        self.endingDate = endingDate
    }
}

enum TransactionStatus: String, Codable {
    case credited, skipped
}

struct ResponseTransaction: Codable {
    var transactionType: TransactionType
    var transactionStatus: TransactionStatus
    var occurrence: Int
    
    var title: String
    var value: Float
    var paymentType: PaymentType
    var category: String
    
    var transactionDate: Date
}

struct ResponseTransactions: Content, Response {
    var error = false
    
    var staringDate: Date
    var endingDate: Date
    
    var transactions: [ResponseTransaction]
}


struct PostTransaction: Content, Validatable {
    var transactionType: TransactionType
    var title: String
    var value: Float
    var paymentType: PaymentType
    var category: String

    // exclusive for unique transactions
    var transactionDate: Date?

    // exclusive for recurring transactions
    var startingDate: Date?

    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty && .count(...100))
        validations.add("value", as: Float.self, is: .range(0...))
        
        validations.add("recurrenceDay", as: Int8.self, is: .range(0...31), required: false)
    }

    func toModel(user: User, category: Category) throws -> any Transaction {
        switch self.transactionType {
        case .recurring:
            guard
                let startingDate = self.startingDate
            else {
                throw Abort(.badRequest, reason: "Malformed syntax")
            }

            return RecurringTransaction(
                userId: try user.requireID(),
                title: self.title,
                value: self.value,
                paymentType: self.paymentType,
                categoryId: try category.requireID(),
                startingDate: Calendar.current.startOfDay(for: startingDate)
            )
        case .unique:
            guard let transactionDate = self.transactionDate else {
                throw Abort(.badRequest, reason: "Malformed syntax")
            }

            return UniqueTransaction(
                userId: try user.requireID(),
                title: self.title,
                value: self.value,
                paymentType: self.paymentType,
                categoryId: try category.requireID(),
                transactionDate: Calendar.current.startOfDay(for: transactionDate)
            )
        }
    }
}
