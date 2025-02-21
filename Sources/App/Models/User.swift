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

    @Field(key: "salary")
    var salary: Float

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    required init() { }

    init(
        id: UUID? = nil,
        username: String,
        email: String,
        passwordHash: String,
        salary: Float = 0
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.salary = salary
    }

    func toResponseDTO() -> ResponseUser {
        return .init(
            id: self.id,
            username: self.username,
            email: self.email,
            salary: self.salary
        )
    }

    func generateToken() throws -> UserToken {
        return .init(
            userId: try self.requireID(),
            expiration: .init(value: .init(timeInterval: 60 * 60 * 24 * 90, since: .now))
        )
    }
}
