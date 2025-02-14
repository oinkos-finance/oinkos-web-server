//
//  CreatePaymentType.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 13/02/25.
//

import Fluent

struct CreatePaymentType: AsyncMigration {
    func prepare(on database: Database) async throws {
        let _ = try await database.enum("payment_type")
            .case("creditCard")
            .case("debitCard")
            .case("cash")
            .case("directTransfer")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("payment_type").delete()
    }
}
