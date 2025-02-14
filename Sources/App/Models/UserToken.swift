//
//  UserToken.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/11/24.
//

import Fluent
import JWT
import Vapor

import struct Foundation.UUID

final class UserToken: ModelTokenAuthenticatable, @unchecked Sendable {
    static let schema = "user_token"
    static let userKey = \UserToken.$user
    static let valueKey = \UserToken.$token
    static let expirationTime: TimeInterval = 60 * 60 * 24 * 90 // 90 days
    var isValid: Bool {
        do {
            try self.expiration.verifyNotExpired()
        } catch {
            return false
        }

        return true
    }

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "token")
    var token: String

    @Field(key: "expiration")
    var expiration: ExpirationClaim
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    required init() {}

    init(id: UUID? = nil, userId: User.IDValue, token: String) {
        self.id = id
        self.$user.id = userId
        self.token = token
        self.expiration = ExpirationClaim(
            value: Date().addingTimeInterval(UserToken.expirationTime))
    }

    func toResponseDTO() -> UserTokenResponseDTO {
        .init(token: self.token)
    }
}
