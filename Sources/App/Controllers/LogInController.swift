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
        
        login.grouped(User.authenticator()).post(use: self.getToken)
    }
    
    @Sendable
    func getToken(request: Request) async throws -> UserTokenDTO {
        let userToken = try request.auth.require(User.self).generateToken()
        
        try await userToken.save(on: request.db)
        
        return userToken.toDTO()
    }
}
