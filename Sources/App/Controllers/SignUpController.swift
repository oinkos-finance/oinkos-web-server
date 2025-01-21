//
//  SignUpController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 18/11/24.
//

import Vapor
import JWT

struct SignUpController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let signUp = routes.grouped("signup")
        
        signUp.post(use: self.createUser)
    }
    
    @Sendable
    func createUser(request: Request) async throws -> UserTokenResponseDTO {
        try UserCreateDTO.validate(content: request)
        let createUser = try request.content.decode(UserCreateDTO.self)
        
        guard let user = try? createUser.toModel() else {
            throw Abort(.badRequest, reason: "Mismatched passwords")
        }
        
        try await user.save(on: request.db)
        
        let token = try user.generateToken()
        try await token.save(on: request.db)
        
        return token.toResponseDTO()
    }
}
