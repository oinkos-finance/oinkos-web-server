//
//  UserTokenDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/11/24.
//

import Vapor
import JWT

struct UserTokenDTO: Content, JWTPayload {
    var id: UUID?
    var userId: UUID
    var token: String
    var expiration: ExpirationClaim
    
    func toModel() -> UserToken {
        .init(id: self.id, userId: self.userId, token: self.token)
    }
    
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }

}

struct UserTokenResponseDTO: Content {
    var token: String
}
