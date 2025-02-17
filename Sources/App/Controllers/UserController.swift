//
//  UserController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Fluent
import JWT
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let user = routes.grouped("user")

        user.grouped(
            UserToken.authenticator(),
            UserToken.guardMiddleware(
                throwing: Abort(.unauthorized, reason: "Unauthorized"))
        )
        .get(use: self.getCurrentUser)
    }

    @Sendable
    func getCurrentUser(request: Request) async throws(Abort) -> ResponseUser
    {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(
                \.$id == userToken.userId
            ).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        return user.toResponseDTO()
    }
}
