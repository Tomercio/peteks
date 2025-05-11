<!--
  README.md  –  Peteks ✨
  A cozy, theme-able note-taking app with rich-text editing & automatic Drive backups
-->

<p align="center">
  <img src="assets/icons/playstore.png" height="120" alt="Peteks logo" />
</p>

<h1 align="center">Peteks</h1>
<p align="center">
  <i>Take notes.  Keep them safe.  Feel comfy.</i>
</p>

---

## ✨ Highlights

| | |
|---|---|
| 🎨 **Two “Comfy” themes** | _Comfy Light_ & _Comfy Dark_, inspired by pastel stationery. |
| 🖋 **Rich-text editor** | Powered by **Flutter Quill** – headings, lists, links, images & more. |
| 🗂 **Grid / list view** | Switch instantly; cards show a rich-text preview or plain text. |
| 🔔 **Exact reminders** | Schedule precise alarms (Android 12+ compatible) for any note. |
| ☁️ **Google Drive backup** | One-tap sign-in backs up all notes to your private Drive folder. |
| 🔒 **Secure notes** | Optional PIN-lock for sensitive notes (no data leaves your device). |
| 📦 **100 % offline-first** | Works without internet; sync only when **you** ask. |


---

## 🚀 Getting Started

# 1. clone
git clone https://github.com/your-username/peteks.git
cd peteks

# 2. fetch dependencies
flutter pub get

# 3. run (device / emulator must be connected)
flutter run

---
🛠 Tech Stack

| Layer             | Libraries                                          |
| ----------------- | -------------------------------------------------- |
| **UI**            | Flutter 3, Provider, Flutter Quill                 |
| **Storage**       | `hive` local DB, Google Drive REST v3              |
| **Auth**          | `google_sign_in`, OAuth 2                          |
| **Notifications** | `flutter_local_notifications`, exact-alarm support |
| **Build**         | Gradle 8 / Kotlin 1.9, GitHub Actions CI           |

---

💡 Roadmap
 iOS Drive-backup via Sign in with Apple + iCloud Drive

 Tag system & fast search

 Web companion app

 Multi-select & batch actions

Vote or open an issue with your ideas!

---

🤝 Contributing

⭐ Star the repo (motivation FTW)

1. Fork & create a feature branch

2. flutter analyze must pass and flutter test should stay green

3. Open a pull request – we love clean, well-commented code 🙂

4. See CONTRIBUTING.md for style conventions.

---

📃 License
Peteks is released under the MIT License © 2025 Tomer & Contributors.
Feel free to use, modify, and share – just keep the credits.

<p align="center">
  <img src="assets/icons/playstore.png" height="60" alt="Peteks mini logo" />
</p>

🔹 How to use:

Save the block above as README.md in your repo root.

Replace placeholders (your-username, screenshot paths, etc.).

Commit & push – GitHub will render it automatically.

Enjoy your brand-new, pretty README!
