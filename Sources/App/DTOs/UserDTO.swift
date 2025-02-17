//
//  UserDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor

struct PostUser: Content, Validatable {
    var username: String
    var email: String
    var password: String
    var confirmPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }

    func toModel() throws -> User {
        guard self.password == self.confirmPassword else {
            throw Abort(.unprocessableEntity, reason: "Passwords must match")
        }

        return User(
            username: self.username,
            email: self.email,
            passwordHash: try Bcrypt.hash(self.password)
        )
    }
}

struct ResponseUser: Content, Response {
    var error: Bool = false
    var id: UUID?
    var username: String
    var email: String
    var balance: Float
}
