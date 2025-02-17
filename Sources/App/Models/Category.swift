import Fluent
import Foundation

final class Category: Model, @unchecked Sendable {
    static let schema = "category"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "name")
    var name: String

    @Children(for: \.$category)
    var uniqueTransactions: [UniqueTransaction]

    @Children(for: \.$category)
    var recurringTransactions: [RecurringTransaction]

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    required init() { }

    init(
        id: UUID? = nil,
        userId: User.IDValue,
        name: String
    ) {
        self.id = id
        self.$user.id = userId
        self.name = name
    }
}
