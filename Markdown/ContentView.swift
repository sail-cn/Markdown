//
//  ContentView.swift
//  Markdown
//
//  Created by Yanxi Feng on 2025/7/10.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var documentHandler: DocumentHandler
    
    var body: some View {
        FileBrowserView()
            .environmentObject(documentHandler)
    }
}

#Preview {
    ContentView()
        .environmentObject(DocumentHandler())
}
