import Vapor

struct PostUser: Content, Validatable {
    var username: String
    var email: String
    var password: String
    var confirmPassword: String
    var salary: Float?

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("salary", as: Float.self, is: .range(0...))
    }

    func toModel() throws -> User {
        guard self.password == self.confirmPassword else {
            throw Abort(.unprocessableEntity, reason: "Passwords must match")
        }

        return User(
            username: self.username,
            email: self.email,
            passwordHash: try Bcrypt.hash(self.password),
            salary: self.salary ?? 0
        )
    }
}

struct ResponseUser: Content, Response {
    var error: Bool = false
    var id: UUID?
    var username: String
    var email: String
    var salary: Float
}
