# Changelog

All notable changes to Peteks will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-05-30

### Added
- Rich text editor powered by Flutter Quill
- Comfy Light & Comfy Dark themes with full system-default support
- Google Drive backup and restore
- Secure notes with pattern or password lock (HMAC-SHA256 + per-note salt)
- Folders & categories system with horizontal chip bar
- Checklist / todo support in the Quill toolbar
- Tags, favorites, and pinning
- Image attachments (gallery & camera) and voice recording
- Calendar view for notes
- Onboarding flow for first-time users (4-page walkthrough)
- Sort options: last modified, date created, A→Z, Z→A
- Auto-save with 2-second debounce and subtle AppBar indicator
- Undo for note deletion (4-second SnackBar)
- Note word count and character count in the editor
- Hebrew locale registration for RTL content support
- Beautiful empty states for all filter modes
- Folder management (create, rename, delete)

### Fixed
- Grid view no longer capped at 9 notes
- Unified theme system — removed conflicting ThemeProvider
- Search now extracts plain text from Quill Delta JSON
- Hardcoded LTR text direction removed from the Quill editor
- Password option added to the secure-note dialog
- Error feedback shown when image pick or camera fails
