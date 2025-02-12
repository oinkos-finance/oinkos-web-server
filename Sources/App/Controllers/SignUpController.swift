//
//  SignUpController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 18/11/24.
//

import JWT
import Vapor

struct SignUpController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let signUp = routes.grouped("signup")

        signUp.post(use: self.createUser)
    }

    @Sendable
    func createUser(request: Request) async throws(Abort) -> UserTokenResponseDTO {
        guard let createUser = try? request.content.decode(UserCreateDTO.self) else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }

        guard (try? UserCreateDTO.validate(content: request)) != nil else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }

        var user: User
        do {
            user = try createUser.toModel()
        } catch is Abort {
            throw Abort(.badRequest, reason: "Mismatched passwords")
        } catch {
            throw Abort(.internalServerError)
        }

        guard (try? await user.save(on: request.db)) != nil else {
            throw Abort(.internalServerError, reason: "Failed to save user")
        }
        
        guard let token = try? user.generateToken() else {
            throw Abort(.internalServerError, reason: "Unable to generate authentication token for user")
        }
        
        guard (try? await token.save(on: request.db)) != nil else {
            throw Abort(.internalServerError, reason: "Failed to save user authentication token")
        }

        return token.toResponseDTO()
    }
}
