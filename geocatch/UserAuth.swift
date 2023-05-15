//
//  UserAuth.swift
//  geocatch
//
//  Created by Sabrina Serres on 12/05/2023.
//

import Foundation

class UserAuth: ObservableObject {
    
    @Published var isLoggedIn = false
    @Published var username: String = ""

    
    func authenticateUser(username: String, password: String) {
        // Perform authentication logic here
        // ...
        isLoggedIn = true
    }
    
    func logout() {
        // Perform logout logic here
        // ...
        isLoggedIn = false
    }
}
