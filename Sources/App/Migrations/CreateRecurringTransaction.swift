//
//  CreateRecurringTransaction.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 13/02/25.
//

import Fluent

struct CreateRecurringTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(RecurringTransaction.schema)
            .id()
            .field("user_id", .uuid, .required, .references("user", "id", onDelete:  .cascade)) 
            .field("title", .string, .required)
            .field("value", .float, .required)
            .field("payment_type", database.enum("payment_type").read())
            .field("recurrence_day", .int8, .required)
            .field("starting_date", .date, .required)
            .field("skipped_occurrences", .array(of: .int))
            .field("end_date", .date)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(RecurringTransaction.schema).delete()
    }
}

