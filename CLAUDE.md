# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iCommander is a dual-pane file manager for macOS, inspired by Norton Commander and Total Commander. It provides a two-panel interface for efficient file operations between directories.

## Build Commands

```bash
# Build the project
xcodebuild -project iCommander.xcodeproj -scheme iCommander-MacOS -configuration Debug build

# Build for release
xcodebuild -project iCommander.xcodeproj -scheme iCommander-MacOS -configuration Release build

# Clean build
xcodebuild -project iCommander.xcodeproj -scheme iCommander-MacOS clean
```

The project can also be opened and built directly in Xcode: `open iCommander.xcodeproj`

## Git Workflow

**Never commit directly to the main branch.** Always create a feature branch for your changes:

```bash
git checkout -b feature/your-feature-name
# make changes
git add -A && git commit -m "Your commit message"
git push -u origin feature/your-feature-name
# create PR via: gh pr create
```

## Architecture

### Core Components

**ViewController.swift** - Main coordinator that manages both file panels, handles user interactions, and coordinates between data sources and file operations.

**TableDataSource.swift** - Data model for each panel. Manages the list of `TableElement` objects (files/folders), handles sorting, and tracks current directory state. Each panel has its own instance identified by `LocationOnScreen` (.Left or .Right).

**FileOperations.swift** - Handles all file system operations (copy, move, delete, rename). Uses background queues for long operations with chunked file copying (5KB chunks) for large files. Implements pause/resume/cancel via a state machine.

**TableView.swift** - Custom NSTableView subclass that handles keyboard shortcuts (F3-F8, Tab, Enter, Delete, Cmd+Up).

### Data Flow

1. User interaction → ViewController
2. ViewController → TableDataSource (for data) or FileOperations (for operations)
3. FileOperations → FileOperationsDelegate callbacks → ViewController updates UI
4. TableDataSource changes → DataSourceDelegate → ViewController refreshes tables

### Delegate Protocols

- **FileOperationsDelegate**: Progress updates during copy/move (copyStarted, copyUpdateProgress, fileOperationCompleted)
- **DataSourceDelegate**: Notifies when current path changes (currentURLChanged)
- **TableViewDelegate**: Custom keyboard event handling (handleTab, handleEnter, handleDelete, etc.)

### Persistence

Core Data stores user state:
- **TableViewData**: Current path and hidden files setting per panel
- **Favorites**: User's bookmarked folders

### Key Keyboard Shortcuts

Defined in Constants.swift:
- F3 (99): Quick Look preview
- F4 (118): Open file in default application
- F5 (96): Copy files to opposite panel
- F6 (97): Move files to opposite panel
- F7 (98): Create new folder
- F8 (100): Delete selected files
- Tab (48): Switch between panels
- Cmd+Up: Navigate to parent directory

### File Operation States

FileOperations uses a state machine: `.Running` → `.Paused` → `.Running` or `.Stopped` → `.Finished`

Progress is tracked via `totalBytesToCopy` and `totalBytesCopied` for overall progress, with per-file progress during chunked copies.
