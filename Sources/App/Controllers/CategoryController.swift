//
//  CategoryController.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 23/02/25.
//

import Fluent
import Vapor

struct CategoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) {
        let category = routes.grouped("category")
        
        category.grouped(
            UserToken.authenticator(),
            UserToken.guardMiddleware(throwing: Abort(.unauthorized, reason: "Unauthorized"))
        ).get(use: self.getAllCategories)
    }
    
    @Sendable
    func getAllCategories(request: Request) async throws(Abort) -> ResponseCategory {
        guard
            let userToken = try? request.auth.require(UserToken.self),
            let user = try? await User.query(on: request.db).filter(\.$id == userToken.userId).first()
        else {
            throw Abort(.unauthorized, reason: "Unauthorized")
        }
        
        let categories: [Category]
        do {
            categories = try await Category.query(on: request.db).filter(\.$user.$id == user.requireID()).all()
        } catch {
            throw Abort(.internalServerError, reason: "Unable to fetch categories from the database")
        }
        
        let categoryNames: [String] = categories.map { category in
            return category.name
        }
        
        return .init(categories: categoryNames)
    }
}
