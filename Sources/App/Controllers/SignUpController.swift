//
//  SignUpController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 18/11/24.
//

import JWT
import Vapor
import Fluent

struct SignUpController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let signUp = routes.grouped("signup")

        signUp.post(use: self.createUser)
    }

    @Sendable
    func createUser(request: Request) async throws(Abort) -> UserTokenResponse {
        guard let createUser = try? request.content.decode(PostUser.self) else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }

        guard (try? PostUser.validate(content: request)) != nil else {
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

        do {
            try await user.save(on: request.db)
        } catch let error as DatabaseError where error.isConstraintFailure {
            throw Abort(.badRequest, reason: "A user with that username already exists")
        } catch {
            throw Abort(.internalServerError, reason: "Failed to save user")
        }
        
        guard
            let token = try? user.generateToken(),
            let signedToken = try? await request.jwt.sign(token)
        else {
            throw Abort(.internalServerError, reason: "Unable to generate authentication token for user")
        }

        return .init(token: signedToken)
    }
}
