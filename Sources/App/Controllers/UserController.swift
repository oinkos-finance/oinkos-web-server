//
//  UserController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor
import Fluent
import JWT

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let users = routes.grouped("user")

        users.grouped(
            UserToken.authenticator(), UserToken.guardMiddleware()
        ).get(use: self.getCurrentUser)
    }

    @Sendable
    func getCurrentUser(request: Request) async throws(Abort) -> UserResponseDTO {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(\.$id == userToken.userId).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        return user.toResponseDTO()
    }
}
