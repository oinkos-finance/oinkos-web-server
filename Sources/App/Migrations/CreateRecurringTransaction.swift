import Fluent

struct CreateRecurringTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(RecurringTransaction.schema)
            .id()
            .field("user_id", .uuid, .required, .references("user", "id", onDelete:  .cascade)) 
            .field("title", .string, .required)
            .field("value", .float, .required)
            .field("payment_type", database.enum("payment_type").read())
            .field("category_id", .uuid, .required, .references("category", "id", onDelete: .restrict))
            .field("starting_date", .date, .required)
            .field("skipped_occurrences", .array(of: .int), .required)
            .field("ending_date", .date)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(RecurringTransaction.schema).delete()
    }
}

