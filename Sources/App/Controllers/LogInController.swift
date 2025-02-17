import Vapor

struct LogInController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let logIn = routes.grouped("login")

        logIn.grouped(
            User.authenticator(),
            User.guardMiddleware(
                throwing: Abort(.unauthorized, reason: "Unauthorized"))
        )
        .post(use: self.getToken)
    }

    @Sendable
    func getToken(request: Request) async throws(Abort) -> ResponseUserToken {
        guard let user = try? request.auth.require(User.self) else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        guard
            let token = try? user.generateToken(),
            let signedToken = try? await request.jwt.sign(token)
        else {
            throw Abort(
                .internalServerError,
                reason: "Unable to generate authentication token for user")
        }

        return .init(token: signedToken)
    }
}
