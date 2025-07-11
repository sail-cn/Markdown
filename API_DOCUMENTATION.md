# Markdown Viewer API Documentation

## Table of Contents

- [Overview](#overview)
- [App Architecture](#app-architecture)
- [Core Components](#core-components)
- [Data Models](#data-models)
- [Extensions](#extensions)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)

## Overview

This is a SwiftUI-based Markdown viewer application for macOS that provides a file browser interface for navigating and viewing Markdown files. The app features a split-view interface with file browser on the left and markdown content viewer on the right.

**Key Features:**
- Browse local documents directory
- Open external Markdown files
- Render Markdown content with custom styling
- Support for multiple Markdown file formats (.md, .markdown, .mdown, .mkdn, .mkd)
- File sharing and content copying
- Automatic sample file creation

## App Architecture

The application follows a clean SwiftUI architecture with the following main components:

```
MarkdownApp (Main App)
├── ContentView (Root View)
    └── FileBrowserView (File Browser)
        ├── FileItemRow (File List Item)
        └── MarkdownDetailView (Detail View)
            └── MarkdownRenderer (Content Renderer)
                └── MarkdownText (Text Renderer)
```

## Core Components

### 1. MarkdownApp

**Purpose:** Main application entry point

**Location:** `Markdown/MarkdownApp.swift`

**Definition:**
```swift
@main
struct MarkdownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Usage:**
- This is the main entry point of the SwiftUI application
- Automatically creates a window group containing the main content view
- Uses the `@main` attribute to mark it as the app's entry point

### 2. ContentView

**Purpose:** Root view wrapper that displays the file browser

**Location:** `Markdown/ContentView.swift`

**Definition:**
```swift
struct ContentView: View {
    var body: some View {
        FileBrowserView()
    }
}
```

**Usage:**
- Simple wrapper view that displays the main file browser
- Serves as the root view for the application
- Can be extended to add global app state or navigation

### 3. FileBrowserView

**Purpose:** Main file browser interface with split-view layout

**Location:** `Markdown/FileBrowserView.swift`

**Public API:**

#### Initializer
```swift
init(directory: URL = FileManager.default.documentsDirectory)
```

**Parameters:**
- `directory`: Starting directory for file browsing (defaults to Documents directory)

#### State Properties
- `@State private var fileItems: [FileItem]` - Array of file items in current directory
- `@State private var currentDirectory: URL` - Current directory being browsed
- `@State private var selectedFile: FileItem?` - Currently selected file
- `@State private var showingMarkdownFile: Bool` - Whether markdown file is being displayed
- `@State private var isLoading: Bool` - Loading state indicator
- `@State private var errorMessage: String?` - Error message for display
- `@State private var showingFilePicker: Bool` - File picker presentation state
- `@State private var openedExternalFile: FileItem?` - Externally opened file

#### Key Methods

##### `setupInitialFiles()`
```swift
private func setupInitialFiles()
```
- Creates sample Markdown files if none exist
- Called automatically when view appears

##### `loadFiles()`
```swift
private func loadFiles()
```
- Loads files from current directory
- Updates UI with loading state
- Handles errors gracefully

##### `handleFileSelection(_ item: FileItem)`
```swift
private func handleFileSelection(_ item: FileItem)
```
- Handles file/directory selection
- Navigates into directories
- Opens Markdown files for viewing

##### `openFileFromSystem()`
```swift
private func openFileFromSystem()
```
- Opens system file picker
- Allows selection of external Markdown files
- Validates file types

**Example Usage:**
```swift
// Basic usage with default directory
FileBrowserView()

// Usage with custom directory
FileBrowserView(directory: URL(fileURLWithPath: "/custom/path"))
```

### 4. FileItemRow

**Purpose:** Individual file item display in the browser list

**Location:** `Markdown/FileBrowserView.swift`

**Public API:**

#### Initializer
```swift
init(item: FileItem, onTap: @escaping () -> Void)
```

**Parameters:**
- `item`: FileItem to display
- `onTap`: Closure called when item is tapped

**Features:**
- Displays file icon based on type
- Shows file name, size, and modification date
- Provides visual indicators for directories and Markdown files
- Supports tap gestures for selection

### 5. MarkdownDetailView

**Purpose:** Detail view for displaying Markdown file content

**Location:** `Markdown/MarkdownDetailView.swift`

**Public API:**

#### Initializer
```swift
init(fileItem: FileItem)
```

**Parameters:**
- `fileItem`: FileItem containing the Markdown file to display

#### State Properties
- `@State private var content: String` - Loaded file content
- `@State private var isLoading: Bool` - Loading state
- `@State private var errorMessage: String?` - Error message
- `@State private var showingAlert: Bool` - Alert presentation state
- `@State private var alertMessage: String` - Alert message content

#### Key Methods

##### `loadFileContent()`
```swift
private func loadFileContent()
```
- Loads file content from disk
- Handles encoding and error cases
- Updates UI with loading states

##### `shareFile()`
```swift
private func shareFile()
```
- Shares the current file using system sharing
- macOS-specific implementation

##### `copyContent()`
```swift
private func copyContent()
```
- Copies file content to clipboard
- Cross-platform implementation

##### `showFileInfo()`
```swift
private func showFileInfo()
```
- Displays file information in alert
- Shows name, size, modification date, and path

**Example Usage:**
```swift
MarkdownDetailView(fileItem: selectedFileItem)
```

### 6. MarkdownRenderer

**Purpose:** Core Markdown rendering engine

**Location:** `Markdown/MarkdownRenderer.swift`

**Public API:**

#### Initializer
```swift
init(content: String, fileName: String = "")
```

**Parameters:**
- `content`: Markdown content to render
- `fileName`: Optional filename to display as header

#### Key Features
- Renders Markdown content with proper styling
- Displays optional file header
- Provides scrollable content view
- Uses custom background styling

**Example Usage:**
```swift
MarkdownRenderer(content: markdownContent, fileName: "README.md")
```

### 7. MarkdownText

**Purpose:** Low-level Markdown text parser and renderer

**Location:** `Markdown/MarkdownRenderer.swift`

**Public API:**

#### Initializer
```swift
init(_ content: String)
```

**Parameters:**
- `content`: Raw Markdown content to parse and render

#### Supported Markdown Features

##### Headers
- `# Header 1` - Large title with bold weight
- `## Header 2` - Title with bold weight  
- `### Header 3` - Title2 with semibold weight

##### Text Formatting
- `**bold text**` - Bold formatting
- `*italic text*` - Italic formatting
- `` `inline code` `` - Monospaced code with background

##### Lists
- `- item` or `* item` - Bullet lists
- `1. item` - Numbered lists

##### Other Elements
- `> quote` - Block quotes with blue left border
- ``` code blocks ``` - Code blocks with background
- `---` or `***` - Horizontal rules

**Example Usage:**
```swift
MarkdownText("""
# My Document
This is **bold** and *italic* text.
- List item 1
- List item 2
""")
```

## Data Models

### FileItem

**Purpose:** Represents a file or directory in the file system

**Location:** `Markdown/FileItem.swift`

**Definition:**
```swift
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
}
```

#### Properties
- `id: UUID` - Unique identifier
- `url: URL` - File system URL
- `name: String` - File/directory name
- `isDirectory: Bool` - Whether item is a directory
- `size: Int64` - File size in bytes
- `modificationDate: Date` - Last modification date

#### Computed Properties

##### `isMarkdownFile: Bool`
```swift
var isMarkdownFile: Bool {
    return FileManager.default.isMarkdownFile(url)
}
```
- Returns true if file is a Markdown file

##### `formattedSize: String`
```swift
var formattedSize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: size)
}
```
- Returns human-readable file size

##### `formattedDate: String`
```swift
var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: modificationDate)
}
```
- Returns formatted modification date

##### `iconName: String`
```swift
var iconName: String {
    if isDirectory {
        return "folder.fill"
    } else if isMarkdownFile {
        return "doc.text.fill"
    } else {
        return "doc.fill"
    }
}
```
- Returns appropriate SF Symbol name

##### `iconColor: String`
```swift
var iconColor: String {
    if isDirectory {
        return "blue"
    } else if isMarkdownFile {
        return "green"
    } else {
        return "gray"
    }
}
```
- Returns appropriate color string

**Example Usage:**
```swift
let fileItem = FileItem(url: URL(fileURLWithPath: "/path/to/file.md"))
print(fileItem.isMarkdownFile) // true
print(fileItem.formattedSize) // "1.2 KB"
print(fileItem.iconName) // "doc.text.fill"
```

## Extensions

### FileManager+Extensions

**Purpose:** Extends FileManager with Markdown-specific functionality

**Location:** `Markdown/FileManager+Extensions.swift`

#### Properties

##### `documentsDirectory: URL`
```swift
var documentsDirectory: URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}
```
- Returns the app's Documents directory URL

#### Methods

##### `contentsOfDirectory(at:) -> [URL]`
```swift
func contentsOfDirectory(at url: URL) -> [URL]
```
- Returns sorted array of URLs in the specified directory
- Skips hidden files
- Handles errors gracefully

**Parameters:**
- `url`: Directory URL to scan

**Returns:**
- Array of file URLs sorted alphabetically

##### `isMarkdownFile(_:) -> Bool`
```swift
func isMarkdownFile(_ url: URL) -> Bool
```
- Checks if file has Markdown extension
- Supports: .md, .markdown, .mdown, .mkdn, .mkd

**Parameters:**
- `url`: File URL to check

**Returns:**
- `true` if file is a Markdown file

##### `createSampleMarkdownFiles()`
```swift
func createSampleMarkdownFiles()
```
- Creates sample Markdown files in Documents directory
- Only creates files that don't already exist
- Creates: Welcome.md, README.md, Features.md

**Example Usage:**
```swift
let fileManager = FileManager.default
let documentsURL = fileManager.documentsDirectory
let files = fileManager.contentsOfDirectory(at: documentsURL)
let markdownFiles = files.filter { fileManager.isMarkdownFile($0) }
```

## Usage Examples

### Basic App Setup

```swift
import SwiftUI

@main
struct MyMarkdownApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Custom File Browser

```swift
struct CustomFileBrowser: View {
    var body: some View {
        FileBrowserView(directory: URL(fileURLWithPath: "/custom/path"))
    }
}
```

### Standalone Markdown Viewer

```swift
struct StandaloneViewer: View {
    let markdownContent = """
    # Welcome
    This is a **sample** markdown document.
    
    ## Features
    - Easy to use
    - Fast rendering
    - Beautiful UI
    """
    
    var body: some View {
        MarkdownRenderer(content: markdownContent, fileName: "Sample.md")
    }
}
```

### File Operations

```swift
// Create a file item
let fileURL = URL(fileURLWithPath: "/path/to/document.md")
let fileItem = FileItem(url: fileURL)

// Check if it's a Markdown file
if fileItem.isMarkdownFile {
    print("This is a Markdown file: \(fileItem.name)")
    print("Size: \(fileItem.formattedSize)")
    print("Modified: \(fileItem.formattedDate)")
}

// Create sample files
FileManager.default.createSampleMarkdownFiles()
```

### Custom Markdown Rendering

```swift
struct CustomMarkdownView: View {
    let content = """
    # Custom Document
    
    This document contains:
    - **Bold text**
    - *Italic text*
    - `inline code`
    
    > This is a quote
    
    ```swift
    // Code block
    print("Hello, World!")
    ```
    """
    
    var body: some View {
        ScrollView {
            MarkdownText(content)
                .padding()
        }
    }
}
```

## API Reference

### Constants

#### Supported File Extensions
```swift
private let markdownExtensions = ["md", "markdown", "mdown", "mkdn", "mkd"]
```

#### Sample Content
The app includes three sample Markdown files:
- `Welcome.md` - Introduction and feature overview
- `README.md` - Technical documentation
- `Features.md` - Detailed feature list with planned enhancements

### Error Handling

The application provides comprehensive error handling:

1. **File Loading Errors**
   - Invalid file paths
   - Permission issues
   - Encoding problems

2. **Directory Navigation Errors**
   - Invalid directory paths
   - Permission denied
   - Network unavailable (for network paths)

3. **Markdown Rendering Errors**
   - Malformed markdown syntax
   - Unsupported content types

### Performance Considerations

1. **Asynchronous Operations**
   - File loading is performed on background queues
   - UI updates are dispatched to main queue
   - Loading states prevent UI blocking

2. **Memory Management**
   - Large files are loaded on-demand
   - Content is cached during viewing session
   - Memory is released when views are dismissed

3. **Efficient Parsing**
   - Markdown parsing is optimized for common syntax
   - Regular expressions are compiled once
   - Attributed strings are built efficiently

### Platform Compatibility

The app is designed for macOS and includes:
- macOS-specific file picker (NSOpenPanel)
- macOS-specific sharing (NSSharingServicePicker)
- macOS-specific pasteboard operations
- Cross-platform fallbacks where possible

### Accessibility

The app includes accessibility features:
- VoiceOver support for all UI elements
- Semantic labels for file icons
- Keyboard navigation support
- High contrast mode compatibility

---

*Last updated: January 2025*
*Version: 1.0*