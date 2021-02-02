//
//  hand_painted_book_appApp.swift
//  hand-painted book app
//
//  Created by 林聖哲 on 2020/12/28.
//

import SwiftUI
import Firebase
@main
struct hand_painted_book_appApp: App {
    
    init(){
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
