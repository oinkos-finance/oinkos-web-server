//
//  UserController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 16/11/24.
//

import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        
        users.group(":userId") { user in
            user.get(use: self.getUser)
        }
    }
    
    @Sendable
    func getUser(request: Request) async throws -> UserResponseDTO {
        guard let user = try? await User.find(request.parameters.get(":userId"), on: request.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        return user.toResponseDTO()
    }
}
