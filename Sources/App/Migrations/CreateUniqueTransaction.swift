import Fluent

struct CreateUniqueTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UniqueTransaction.schema)
            .id()
            .field("user_id", .uuid, .required, .references("user", "id", onDelete:  .cascade))
            .field("title", .string, .required)
            .field("value", .float, .required)
            .field("payment_type", database.enum("payment_type").read())
            .field("transaction_date", .date, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(UniqueTransaction.schema).delete()
    }
}
