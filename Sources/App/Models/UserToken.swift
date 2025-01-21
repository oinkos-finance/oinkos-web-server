//
//  UserToken.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/11/24.
//

import Fluent
import Vapor
import JWT

import struct Foundation.UUID

final class UserToken: ModelTokenAuthenticatable, @unchecked Sendable {
    static let schema = "user_token"
    static let userKey = \UserToken.$user
    static let valueKey = \UserToken.$token
    static let expirationTime: TimeInterval = 60 * 15
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
    
    init() { }
    
    init(id: UUID? = nil, userId: User.IDValue, token: String) {
        self.id = id
        self.$user.id = userId
        self.token = token
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(UserToken.expirationTime))
    }
    
    func toDTO() -> UserTokenDTO {
        .init(id: self.id, userId: self.$user.id, token: self.token, expiration: self.expiration)
    }
}
