# 🎤 Karaoke Maker

Turn any YouTube song into a karaoke track in minutes — the app removes the vocals automatically using AI, leaving you with just the music.

---

## What it does

1. You paste a YouTube link.
2. The app downloads the audio.
3. AI removes the vocals.
4. You get an MP3 file saved to your **Karaoke Music** folder.

That's it. No technical knowledge needed.

---

## One-Time Setup (do this once)

> **You only do this once.** After setup, you just double-click **launch.bat** every time.

### Step 1 — Install Python

1. Open your web browser and go to: **https://www.python.org/downloads/**
2. Click the big yellow **Download Python** button.
3. Run the file that downloads.
4. **Very important:** On the first screen of the installer, check the box that says **"Add Python to PATH"**.
5. Click **Install Now** and wait for it to finish.

### Step 2 — Run the Setup Script

1. Open the **youtubekaraoke** folder on your computer.
2. Double-click the file called **setup.bat**.
3. A black window will appear. **Do not close it.** Let it run.
4. It will download several things including an AI model. This can take **10–20 minutes** depending on your internet speed.
5. When you see **"Setup is complete!"**, you can close the window.

> **Tip:** If Windows shows a warning saying "Windows protected your PC", click **More info** and then **Run anyway**. This is normal for scripts you download.

---

## Using the App (every day)

1. Double-click **launch.bat**.
2. Wait a few seconds — Karaoke Maker will open in Google Chrome automatically.
3. Paste a YouTube link into the box and click **Make Karaoke Track!**
4. Wait 3–10 minutes while the app works. **Do not close the black window or the browser tab.**
5. When it's done, you'll see a success message with the file name.
6. Click **Open Folder** to see your karaoke MP3.

Your karaoke files are saved here:

```
C:\Users\YourName\Karaoke Music\
```

---

## Troubleshooting

**The browser doesn't open automatically**
Open Google Chrome yourself and type `http://localhost:5000` in the address bar.

**"Python is not installed" error during setup**
Follow Step 1 above. Make sure to check **"Add Python to PATH"** during installation.

**"Something went wrong" in the app**
- Check that your internet connection is working.
- Make sure the YouTube link is a real, public YouTube video.
- Try a different song.
- If the black window (launcher) was closed, restart by double-clicking **launch.bat**.

**Processing seems stuck**
Some songs take up to 10 minutes to process on slower computers — this is normal. As long as the progress bar is moving, the app is working. Do not close anything.

**The app says the setup isn't complete**
Run **setup.bat** again and let it finish completely before using **launch.bat**.

---

## System Requirements

- Windows 10 or 11
- Google Chrome
- At least 4 GB of RAM (8 GB recommended)
- Internet connection for setup and downloading YouTube audio
- About 3 GB of free disk space (for Python, AI model, and tools)

---

## Privacy & Safety

- **All processing happens on your computer.** No audio is sent to any server.
- The only internet connection used is to download the YouTube audio and (during setup) to install the software.
- Your karaoke files belong to you and stay on your machine.

---

## Files in this folder

| File | What it does |
|------|-------------|
| `setup.bat` | One-time setup — installs everything you need |
| `launch.bat` | Opens Karaoke Maker in Chrome |
| `app.py` | The app's brain (Python code — don't edit) |
| `requirements.txt` | List of software the app needs |
| `templates/` | The app's web pages |
| `static/` | The app's styling and logic |

---

*Built with Python, Flask, yt-dlp, and Demucs (Meta AI).*
