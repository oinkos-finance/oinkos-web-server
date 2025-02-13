//
//  UserController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let users = routes.grouped("user")

        users.grouped(
            UserToken.authenticator()
        ).get(use: self.getCurrentUser)
    }

    @Sendable
    func getCurrentUser(request: Request) async throws(Abort) -> UserResponseDTO {
        guard let userToken = try? request.auth.require(UserToken.self) else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        return userToken.user.toResponseDTO()
    }
}
