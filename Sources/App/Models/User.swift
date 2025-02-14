//
//  User.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Fluent
import Vapor

import struct Foundation.UUID

final class User: ModelAuthenticatable, @unchecked Sendable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }

    static let schema = "user"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "balance")
    var balance: Float
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    required init() { }

    init(id: UUID? = nil, username: String, email: String, passwordHash: String, balance: Float = 0) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.balance = balance
    }

    func toResponseDTO() -> UserResponseDTO {
        return .init(id: self.id, username: self.username, email: self.email, balance: self.balance)
    }

    func generateToken() throws -> UserToken {
        return .init(
            userId: try self.requireID(),
            token: [UInt8].random(count: 16).base64
        )
    }
}
