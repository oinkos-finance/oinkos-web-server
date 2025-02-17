import Fluent

struct CreateCategory: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Category.schema)
            .id()
            .field("user_id", .uuid, .required, .references("user", "id", onDelete:  .cascade))
            .field("name", .string, .required)
            .field("value", .float, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Category.schema).delete()
    }
}
