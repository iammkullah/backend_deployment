import os
import glob
import shutil
from RealtimeTTS import TextToAudioStream, EdgeEngine
import time
import subprocess

def text_to_speech(text, audio_path):
    sample_text = text
    engine = EdgeEngine()
    engine.set_voice('en-US-AndrewNeural')
    stream = TextToAudioStream(engine)

    stream.feed(sample_text).play_async(output_wavfile=audio_path, log_synthesized_text=True)

    # Wait for the TTS process to complete
    while stream.is_playing():
        time.sleep(0.1)
    
    print(f"Audio saved to file: {os.path.abspath(audio_path)}")

def generate_video(audio_path, image_path, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    cmd = [
        "python", "inference.py",
        "--driven_audio", audio_path,
        "--source_image", image_path,
        "--result_dir", output_dir,
        "--still",
        "--preprocess", "full",
        "--enhancer", "gfpgan",
        "--expression_scale", "1",
        "--ref_eyeblink", "D:/Work/SCIPACE/video_generation/code/backend/SadTalker/examples/ref_video/WDA_KatieHill_000.mp4"
    ]
    subprocess.run(cmd, cwd="SadTalker")

def main():
    input_text_file = "input/text_input.txt"
    input_image_file = "D:/Work/SCIPACE/video_generation/code/input/photo.png"
    audio_output = "D:/Work/SCIPACE/video_generation/code/input/generated_audio.wav"
    video_output_dir = "D:/Work/SCIPACE/video_generation/code/output"

    # Read text from file
    with open(input_text_file, 'r', encoding='utf-8') as file:
        text = file.read()

    print("Converting text to speech...")
    text_to_speech(text, audio_output)
    print("Audio generated successfully.")

    print("Generating video...")
    generate_video(audio_output, input_image_file, video_output_dir)
    print("Video generated successfully. Check the 'output' folder.")

if __name__ == '__main__':
    main()