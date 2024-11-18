//
//  UserDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor

struct UserCreateError: Error { }

struct UserCreateDTO: Content, Validatable {
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
            throw UserCreateError()
        }

        return User(
            username: self.username,
            email: self.email,
            passwordHash: try Bcrypt.hash(self.password)
        )
    }
}

struct UserResponseDTO: Content {
    var id: UUID?
    var username: String
    var email: String
}
