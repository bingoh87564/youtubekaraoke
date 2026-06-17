import os
import sys
import uuid
import threading
import subprocess
import shutil
import tempfile
import re
import time
import logging
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_from_directory

app = Flask(__name__)
logging.basicConfig(level=logging.WARNING)

jobs = {}

OUTPUT_DIR = Path.home() / "Karaoke Music"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def get_ffmpeg_path():
    local = Path(__file__).parent / "ffmpeg" / "ffmpeg.exe"
    if local.exists():
        return str(local)
    try:
        import imageio_ffmpeg
        path = imageio_ffmpeg.get_ffmpeg_exe()
        if path and Path(path).exists():
            return path
    except Exception:
        pass
    found = shutil.which("ffmpeg")
    if found:
        return found
    raise RuntimeError(
        "FFmpeg not found. Please run setup.bat again to fix this."
    )


def sanitize_filename(name: str) -> str:
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "", name)
    name = name.strip(". ")
    return name[:120] if name else "audio"


def fake_progress(job_id: str, start: int, end: int, duration: float):
    steps = 20
    step_size = (end - start) / steps
    step_sleep = duration / steps
    for i in range(steps):
        time.sleep(step_sleep)
        if jobs.get(job_id, {}).get("status") in ("error", "complete"):
            return
        jobs[job_id]["progress"] = int(start + step_size * (i + 1))


def process_video(job_id: str, youtube_url: str):
    temp_dir = None
    try:
        ffmpeg_path = get_ffmpeg_path()
        ffmpeg_dir  = str(Path(ffmpeg_path).parent)

        env = os.environ.copy()
        env["PATH"] = ffmpeg_dir + os.pathsep + env.get("PATH", "")

        temp_dir = Path(tempfile.mkdtemp(prefix=f"karaoke_{job_id}_"))

        # ── Step 1: Download ──────────────────────────────────────────────
        jobs[job_id].update(
            status="downloading",
            message="Downloading audio from YouTube… please wait.",
            progress=8,
        )

        import yt_dlp

        ydl_opts = {
            "format": "bestaudio/best",
            "outtmpl": str(temp_dir / "%(title)s.%(ext)s"),
            "ffmpeg_location": ffmpeg_dir,
            "postprocessors": [
                {
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "wav",
                    "preferredquality": "0",
                }
            ],
            "quiet": True,
            "no_warnings": True,
        }

        video_title = "audio"
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(youtube_url, download=True)
            video_title = info.get("title", "audio")

        wav_files = list(temp_dir.glob("*.wav"))
        if not wav_files:
            raise RuntimeError(
                "Could not download the audio. Please check the YouTube link and try again."
            )

        audio_file = wav_files[0]
        jobs[job_id]["progress"] = 25

        # ── Step 2: Vocal separation ──────────────────────────────────────
        jobs[job_id].update(
            status="separating",
            message="Removing vocals… this usually takes 2–5 minutes. Please keep this window open.",
            progress=28,
        )

        sep_output = temp_dir / "separated"
        sep_output.mkdir(exist_ok=True)

        anim = threading.Thread(
            target=fake_progress, args=(job_id, 28, 82, 240), daemon=True
        )
        anim.start()

        # Temporarily add ffmpeg to PATH so audio-separator can find it
        original_path = os.environ.get("PATH", "")
        os.environ["PATH"] = ffmpeg_dir + os.pathsep + original_path
        try:
            from audio_separator.separator import Separator

            separator = Separator(
                output_dir=str(sep_output),
                output_format="WAV",
                log_level=logging.WARNING,
            )
            separator.load_model(model_filename="UVR-MDX-NET-Inst_HQ_3.onnx")
            output_files = separator.separate(str(audio_file))
        finally:
            os.environ["PATH"] = original_path

        # Find the instrumental (no-vocals) track
        instrumental = None
        for f in output_files:
            if "instrumental" in str(f).lower():
                instrumental = Path(str(f))
                break

        if not instrumental or not instrumental.exists():
            candidates = (
                list(sep_output.glob("*(Instrumental)*.wav"))
                + list(sep_output.glob("*instrumental*.wav"))
            )
            if candidates:
                instrumental = candidates[0]

        if not instrumental or not instrumental.exists():
            raise RuntimeError(
                "Vocal removal did not produce an instrumental track. Please try again."
            )

        # ── Step 3: Export MP3 ────────────────────────────────────────────
        jobs[job_id].update(
            status="converting",
            message="Almost done — saving your karaoke track…",
            progress=85,
        )

        safe_title = sanitize_filename(video_title)
        output_filename = f"{safe_title} (Karaoke).mp3"
        output_path = OUTPUT_DIR / output_filename

        counter = 1
        while output_path.exists():
            output_filename = f"{safe_title} (Karaoke) {counter}.mp3"
            output_path = OUTPUT_DIR / output_filename
            counter += 1

        conv = subprocess.run(
            [
                ffmpeg_path,
                "-i", str(instrumental),
                "-codec:a", "libmp3lame",
                "-q:a", "2",
                "-y",
                str(output_path),
            ],
            capture_output=True,
            text=True,
            timeout=300,
            env=env,
        )

        if conv.returncode != 0:
            raise RuntimeError("Could not convert the audio to MP3. Please try again.")

        jobs[job_id].update(
            status="complete",
            message="Your karaoke track is ready!",
            progress=100,
            filename=output_filename,
            output_dir=str(OUTPUT_DIR),
        )

    except RuntimeError as exc:
        jobs[job_id].update(status="error", message=str(exc), progress=0)
    except Exception as exc:
        jobs[job_id].update(
            status="error",
            message=f"Something unexpected went wrong: {exc}",
            progress=0,
        )
    finally:
        if temp_dir and temp_dir.exists():
            shutil.rmtree(temp_dir, ignore_errors=True)


# ── Routes ─────────────────────────────────────────────────────────────────

@app.after_request
def add_cors(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response


@app.route("/health")
def health():
    return jsonify(ok=True)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/process", methods=["POST"])
def process():
    data = request.get_json() or {}
    url = data.get("url", "").strip()

    if not url:
        return jsonify(error="Please enter a YouTube link."), 400
    if "youtube.com" not in url and "youtu.be" not in url:
        return jsonify(
            error="That doesn't look like a YouTube link. Please paste the full URL."
        ), 400

    job_id = str(uuid.uuid4())
    jobs[job_id] = dict(status="starting", message="Getting started…", progress=5)
    threading.Thread(target=process_video, args=(job_id, url), daemon=True).start()
    return jsonify(job_id=job_id)


@app.route("/status/<job_id>")
def get_status(job_id):
    job = jobs.get(job_id)
    if not job:
        return jsonify(status="not_found", message="Job not found."), 404
    return jsonify(job)


@app.route("/files")
def list_files():
    files = []
    for f in OUTPUT_DIR.glob("*.mp3"):
        stat = f.stat()
        files.append({
            "filename": f.name,
            "display": f.stem,
            "size_mb": round(stat.st_size / (1024 * 1024), 1),
            "modified": stat.st_mtime,
        })
    files.sort(key=lambda x: x["modified"], reverse=True)
    return jsonify(files=files)


@app.route("/audio/<path:filename>")
def serve_audio(filename):
    return send_from_directory(OUTPUT_DIR, filename, conditional=True)


@app.route("/delete/<path:filename>", methods=["DELETE"])
def delete_file(filename):
    try:
        target = (OUTPUT_DIR / filename).resolve()
        if target.parent.resolve() != OUTPUT_DIR.resolve():
            return jsonify(error="Invalid path."), 400
        target.unlink(missing_ok=True)
        return jsonify(ok=True)
    except Exception as exc:
        return jsonify(error=str(exc)), 500


@app.route("/open-folder")
def open_folder():
    try:
        subprocess.Popen(["explorer", str(OUTPUT_DIR)])
    except Exception:
        pass
    return jsonify(ok=True)


if __name__ == "__main__":
    print()
    print("=" * 52)
    print("  Karaoke Maker is running!")
    print("  Open your browser to: http://127.0.0.1:5000")
    print("=" * 52)
    print()
    app.run(host="127.0.0.1", port=5000, debug=False, threaded=True)
