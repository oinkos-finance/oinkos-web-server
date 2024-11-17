//
//  User.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Fluent
import Vapor
import struct Foundation.UUID

final class User: Model, @unchecked Sendable {
    static let schema = "user"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String
    
    init() {}
    
    init(id: UUID? = nil, username: String, email: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
    }
    
    func toResponseDTO() -> UserResponseDTO {
        .init(id: self.id, username: self.username, email: self.email)
    }
}
