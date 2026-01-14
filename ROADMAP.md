# iCommander Roadmap

This document tracks the remaining work needed before publishing to the Mac App Store.

## Critical (Must Complete)

### App Store Requirements
- [ ] **Enable App Sandbox** - Add entitlements in Xcode Signing & Capabilities (template ready at `iCommander/Utils/iCommander-MacOS.entitlements`)
- [ ] **App Icon** - Create app icon in all required sizes (16, 32, 128, 256, 512, 1024px)
- [ ] **Privacy Policy** - Create and host a privacy policy URL

### Fix Non-Functional Features
- [ ] **Context Menu "New Text Document"** - Create empty text file
- [ ] **Context Menu "Rename"** - Trigger inline editing from context menu

## High Priority (Competitive Features)

### Search & Filter
- [ ] Real-time filtering within current directory (type to filter)
- [x] Recursive search across subdirectories (Cmd+F)
- [ ] Search by name, extension, size, date range

### Batch Rename
- [ ] Rename multiple files with patterns
- [ ] Find & replace in filenames
- [ ] Add prefix/suffix, numbering sequences
- [ ] Preview before applying

### Folder Size Calculation
- [ ] Calculate and display folder sizes (currently shows "Dir")
- [ ] Background calculation with caching
- [ ] Option to show/hide folder sizes

## Medium Priority (Enhanced UX)

### Tabs
- [ ] Multiple tabs per panel
- [ ] Drag files between tabs
- [ ] Save/restore tab sessions

### File/Folder Comparison
- [ ] Highlight differences between panels
- [ ] Show files only in left, only in right, or different
- [ ] Sync directories option

### Archive Support
- [ ] View contents of ZIP, TAR, GZ without extracting
- [ ] Create archives from selected files
- [ ] Extract archives to destination panel

### Column Customization
- [ ] Add columns: file type, permissions, owner
- [ ] Show/hide columns
- [ ] Reorder and resize columns
- [ ] Save column layouts

## Low Priority (Polish)

### Preferences Window
- [ ] Create preferences UI (backend exists in PreferencesManager.swift)
- [ ] Keyboard shortcuts customization
- [ ] Appearance settings (font size, icon size)
- [ ] Default behavior options

### Localization
- [ ] Wrap all strings in NSLocalizedString
- [ ] Create .strings files for supported languages

### Additional Features
- [ ] File information sidebar panel
- [ ] Checksum calculation (MD5, SHA-256)
- [ ] Split/merge large files
- [ ] Bookmarks organized into groups
- [ ] Recent locations history

## Completed

- [x] Recursive file search with glob patterns (Cmd+F)
- [x] Quick Look preview (F3)
- [x] Open file in default app (F4)
- [x] Context menu Copy/Paste with overwrite confirmation
- [x] Remove force unwraps
- [x] Replace fatalError() with error alerts
- [x] Convert print() to NSLog()
- [x] Add proper error handling
- [x] Fix file handle leaks
- [x] Update to modern @main attribute
- [x] Create App Sandbox entitlements template
- [x] Create SandboxHelper utility
- [x] Add CLAUDE.md documentation

---

## App Store Submission Checklist

When ready to submit:

- [ ] Enable App Sandbox in Xcode
- [ ] Test all features with sandbox enabled
- [ ] Configure code signing certificates
- [ ] Create App Store Connect listing
- [ ] Upload app icon and screenshots
- [ ] Write app description
- [ ] Set pricing and availability
- [ ] Submit privacy policy URL
- [ ] Archive and upload build
- [ ] Submit for review
