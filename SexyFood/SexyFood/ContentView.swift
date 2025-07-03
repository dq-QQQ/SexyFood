//
//  ContentView.swift
//  SexyFood
//
//  Created by Kyu jin Lee on 6/26/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HStack(spacing: 20) {
                Spacer()
                Button("베스트샷") {
                    print("버튼 1 눌림")
                }
                Spacer()
                Button("달력일기") {
                    print("버튼 2 눌림")
                }
                Spacer()
            }
            Spacer()
            HStack(spacing: 20) {
                Spacer()
                Button("알림트리거") {
                    print("버튼 3 눌림")
                }
                Spacer()
                Button("사진일기저장") {
                    print("버튼 4 눌림")
                }
                Spacer()
            }
            Spacer()
            HStack(spacing: 20) {
                Spacer()
                Button("버튼 5") {
                    print("버튼 5 눌림")
                }
                Spacer()
                Button("버튼 6") {
                    print("버튼 6 눌림")
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .buttonStyle(.borderedProminent)
        
    }
}

#Preview {
    ContentView()
}
