//
//  UserController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let users = routes.grouped("users")

        users.grouped(
            UserToken.authenticator(), UserToken.guardMiddleware()
        ).get(use: self.getCurrentUser)
    }

    @Sendable
    func getCurrentUser(request: Request) async throws -> UserResponseDTO {
        let userToken = try request.auth.require(UserToken.self)
        return userToken.user.toResponseDTO()
    }
}
