import Fluent
import JWT
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) {
        let user = routes.grouped("user")

        user.group(
            UserToken.authenticator(),
            UserToken.guardMiddleware(throwing: Abort(.unauthorized, reason: "Unauthorized"))
        ) { group in
            group.get(use: self.getCurrentUser)
            group.patch(use: self.editUser)
            group.delete(use: self.deleteUser)
        }
    }

    @Sendable
    func getCurrentUser(request: Request) async throws(Abort) -> ResponseUser {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(
                \.$id == userToken.userId
            ).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        return user.toResponseDTO()
    }

    @Sendable
    func editUser(request: Request) async throws(Abort) -> ResponseUser {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(
                \.$id == userToken.userId
            ).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }

        guard (try? PostUser.validate(content: request)) != nil else {
            throw Abort(.unprocessableEntity, reason: "Invalid value(s)")
        }

        guard let patch = try? request.content.decode(PatchUser.self) else {
            throw Abort(.badRequest, reason: "Malformed syntax")
        }

        if let username = patch.username {
            user.username = username
        }

        if let email = patch.email {
            user.email = email
        }

        if
            let password = patch.password,
            let passwordConfirmation = patch.confirmPassword
        {
            if password != passwordConfirmation {
                throw Abort(.unprocessableEntity, reason: "Passwords must match")
            }

            do {
                user.passwordHash = try Bcrypt.hash(password)
            } catch {
                throw Abort(
                    .internalServerError, reason: "Unable to hash password")
            }
        }

        if let salary = patch.salary {
            user.salary = salary
        }

        do {
            try await user.save(on: request.db)
        } catch {
            throw Abort(.internalServerError, reason: "Failed to save updated user")
        }

        return user.toResponseDTO()
    }
    
    @Sendable
    func deleteUser(request: Request) async throws(Abort) -> Success {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(\.$id == userToken.userId).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }
        
        do {
            try await user.delete(on: request.db)
        } catch {
            throw Abort(.internalServerError, reason: "Unable to delete user")
        }
        
        return Success()
    }
}
