//
//  CreateUniqueTransaction.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 14/02/25.
//

import Fluent

struct CreateUniqueTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(UniqueTransaction.schema)
            .id()
            .field("user_id", .uuid, .required, .references("user", "id", onDelete:  .cascade))
            .field("title", .string, .required)
            .field("value", .float, .required)
            .field("category", database.enum("payment_type").read())
            .field("transaction_date", .date, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(UniqueTransaction.schema).delete()
    }
}
