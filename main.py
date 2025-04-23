from fastapi import FastAPI, File, UploadFile, Form, BackgroundTasks, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
import shutil
import os
from generate_video import text_to_speech, generate_video
import uuid

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins in development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

tasks_status = {}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_DIR = os.path.join(BASE_DIR, "input")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")

def process_video_task(task_id, text, image_path, audio_path, video_output_subdir):
    try:
        text_to_speech(text, audio_path)
        generate_video(audio_path, image_path, video_output_subdir)
        video_file = next(f for f in os.listdir(video_output_subdir) if f.endswith('.mp4'))
        tasks_status[task_id]["status"] = "completed"
        tasks_status[task_id]["video_path"] = os.path.join(video_output_subdir, video_file)
    except Exception as e:
        tasks_status[task_id]["status"] = "failed"
        tasks_status[task_id]["error"] = str(e)

@app.post("/generate-video/")
async def generate_video_endpoint(background_tasks: BackgroundTasks, text: str = Form(...), image: UploadFile = File(...)):
    os.makedirs(INPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    task_id = str(uuid.uuid4())
    image_filename = f"{task_id}_{image.filename}"
    image_path = os.path.join(INPUT_DIR, image_filename)
    audio_path = os.path.join(INPUT_DIR, f"{task_id}_generated_audio.wav")
    video_output_subdir = os.path.join(OUTPUT_DIR, task_id)

    with open(image_path, "wb") as buffer:
        shutil.copyfileobj(image.file, buffer)

    tasks_status[task_id] = {"status": "running", "video_path": None}
    background_tasks.add_task(process_video_task, task_id, text, image_path, audio_path, video_output_subdir)

    return {"task_id": task_id, "message": "Video generation started"}

@app.get("/task-status/{task_id}")
async def task_status(task_id: str):
    if task_id not in tasks_status:
        raise HTTPException(status_code=404, detail="Task ID not found")
    return {"task_id": task_id, "status": tasks_status[task_id]["status"], "error": tasks_status[task_id].get("error")}

@app.get("/download-video/{task_id}")
async def download_video(task_id: str):
    if task_id not in tasks_status:
        raise HTTPException(status_code=404, detail="Task ID not found")
    if tasks_status[task_id]["status"] != "completed":
        raise HTTPException(status_code=400, detail="Video generation not completed yet")
    video_file_path = tasks_status[task_id]["video_path"]
    return FileResponse(video_file_path, media_type="video/mp4", filename=os.path.basename(video_file_path))
