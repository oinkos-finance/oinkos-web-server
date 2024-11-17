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
        
        users.post(use: self.create)
    }
    
    @Sendable
    func create(req: Request) async throws -> UserResponseDTO {
        try UserCreateDTO.validate(content: req)
        let createUser = try req.content.decode(UserCreateDTO.self)
        
        guard let user = try? createUser.toModel() else {
            throw Abort(.badRequest, reason: "Mismatched passwords")
        }
        
        try await user.save(on: req.db)
        
        return user.toResponseDTO()
    }
}
