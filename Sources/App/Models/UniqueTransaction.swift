//
//  UniqueTransaction.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 14/02/25.
//

import Vapor

final class UniqueTransaction: Transaction, @unchecked Sendable {
    static let schema = ""
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User

    @Field(key: "title")
    var title: String

    @Field(key: "value")
    var value: Float

    @Enum(key: "category")
    var category: PaymentType
    
    @Field(key: "transaction_date")
    var transactionDate: Date
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    
    required init() { }
    
    init(
        id: UUID? = nil,
        userId: User.IDValue,
        title: String,
        value: Float,
        category: PaymentType,
        transactionDate: Date
    ) {
        self.id = id
        self.$user.id = userId
        self.title = title
        self.value = value
        self.category = category
        self.transactionDate = transactionDate
    }
}
