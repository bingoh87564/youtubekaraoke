# 🎤 Karaoke Maker

Turn any YouTube song into a karaoke track — the AI removes the vocals automatically.

---

## How to Use (after setup)

1. Double-click **Karaoke Maker** on your Desktop.
2. Your browser opens automatically.
3. Paste a YouTube link and click **Make Karaoke Track!**
4. Wait 3–10 minutes — the app does everything for you.
5. Your karaoke MP3 is saved in the **Karaoke Music** folder in your home directory.

> **Tip:** Bookmark `http://localhost:5000` in your browser after the app opens. Then just double-click the desktop icon and use the bookmark — no folders needed.

---

## One-Time Setup

> You only do this once.

### Step 1 — Install Python

1. Go to **https://www.python.org/downloads/**
2. Click the big **Download Python** button.
3. Run the downloaded file.
4. **Important:** On the first screen, check the box **"Add Python to PATH"**.
5. Click **Install Now** and wait for it to finish.

### Step 2 — Run Setup

1. Open the **youtubekaraoke** folder.
2. Double-click **`setup.bat`**.
3. A window appears — **leave it open** until you see **"All done!"**
4. This takes 10–20 minutes (downloading AI tools on first run).
5. A **Karaoke Maker** shortcut appears on your Desktop when finished.

That's it. You never need to open this folder again.

---

## Troubleshooting

**The browser says "This site can't be reached"**
The server isn't running. Double-click the **Karaoke Maker** desktop shortcut to start it, then use your bookmark.

**"Setup Required" message when double-clicking the icon**
Run `setup.bat` first and wait for it to finish completely.

**Processing seems stuck**
Long songs can take up to 10 minutes. As long as the progress bar is moving, the app is working. Keep the browser tab open.

**The shortcut isn't on my Desktop**
Open the `youtubekaraoke` folder, right-click **KaraokeMaker.vbs**, choose **Send to → Desktop (create shortcut)**.

**Windows shows a security warning**
Click **More info** → **Run anyway**. This is normal for local scripts.

---

## System Requirements

- Windows 10 or 11
- Google Chrome (or any modern browser)
- Python 3.10 or newer
- At least 4 GB RAM (8 GB recommended)
- ~4 GB free disk space
- Internet connection (for setup and downloading YouTube audio)

---

## Privacy

Everything runs locally on your computer. No audio is ever sent to any server. The only internet use is downloading the YouTube audio and (during setup) installing software.

---

## Files in This Folder

| File | What it does |
|------|-------------|
| `KaraokeMaker.vbs` | The launcher — double-click to open the app (no terminal window) |
| `loading.html` | Splash screen shown while the server starts |
| `setup.bat` | One-time setup — installs everything and creates the desktop shortcut |
| `app.py` | The backend server (do not edit) |
| `run_demucs.py` | AI vocal-removal helper (do not edit) |
| `requirements.txt` | Package list |
| `templates/` | Web pages |
| `static/` | Styles and scripts |

---

*Powered by Python, Flask, yt-dlp, and Demucs (Meta AI).*
