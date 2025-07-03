//
//  ContentView.swift
//  SexyFood
//
//  Created by Kyu jin Lee on 6/26/25.
//

import SwiftUI

enum ViewType {
    case bestshot
    case diary
    case trigger
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink("Best Shot", value: ViewType.bestshot)
                Spacer().frame(height: 30)
                NavigationLink("Diary", value: ViewType.diary)
                Spacer().frame(height: 30)
                NavigationLink("Trigger", value: ViewType.trigger)
                
            }.navigationDestination(for: ViewType.self) { value in
                switch value {
                case .bestshot: BestShotView()
                case .diary: DiaryView()
                case .trigger: EmptyView()
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
