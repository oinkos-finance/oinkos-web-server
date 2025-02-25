import Fluent
import Vapor

import struct Foundation.UUID

final class RecurringTransaction: Transaction, @unchecked Sendable {
    static let schema = "recurring_transaction"

    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User

    @Field(key: "title")
    var title: String

    @Field(key: "value")
    var value: Float

    @Enum(key: "payment_type")
    var paymentType: PaymentType
    
    @Parent(key: "category_id")
    var category: Category

    @Field(key: "starting_date")
    var startingDate: Date

    @Field(key: "skipped_occurrences")
    var skippedOccurrences: [Int]

    @Field(key: "ending_date")
    var endingDate: Date?

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
        paymentType: PaymentType,
        categoryId: Category.IDValue,
        startingDate: Date,
        skippedOccurrences: [Int] = [],
        endingDate: Date? = nil
    ) {
        self.id = id
        self.$user.id = userId
        self.title = title
        self.value = value
        self.paymentType = paymentType
        self.$category.id = categoryId
        self.startingDate = startingDate
        self.skippedOccurrences = skippedOccurrences
        self.endingDate = endingDate
    }
}
