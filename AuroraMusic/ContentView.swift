//
//  ContentView.swift
//  AuroraMusic
//
//  Created for Aurora Music App
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "music.note")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.purple)
                
                Text("Aurora Music")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("您的音乐，随时随地")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(spacing: 15) {
                    NavigationLink(destination: Text("浏览页面")) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                            Text("浏览")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: Text("搜索页面")) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("搜索")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: Text("我的音乐")) {
                        HStack {
                            Image(systemName: "person")
                            Text("个人")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Aurora Music")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}