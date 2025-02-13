//
//  LogInController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 18/11/24.
//

import Vapor

struct LogInController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let login = routes.grouped("login")
        
        login.grouped(
            User.authenticator(), User.guardMiddleware()
        ).post(use: self.getToken)
    }
    
    @Sendable
    func getToken(request: Request) async throws -> UserTokenResponseDTO {
        guard let user = try? request.auth.require(User.self) else {
            throw Abort(.unauthorized, reason: "Unauthorized")
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
