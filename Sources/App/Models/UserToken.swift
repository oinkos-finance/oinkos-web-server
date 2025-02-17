import Vapor
import JWT

struct UserToken: Content, Authenticatable, JWTPayload {
    var userId: UUID
    var expiration: ExpirationClaim
    
    func verify(using algorithm: some JWTKit.JWTAlgorithm) async throws(Abort) {
        do {
            try self.expiration.verifyNotExpired()
        } catch {
            throw Abort(.internalServerError, reason: "Invalid JWT")
        }
    }
}
