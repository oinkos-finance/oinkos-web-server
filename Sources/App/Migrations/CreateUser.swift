//
//  CreateUser.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("username", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .unique(on: "username")
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
