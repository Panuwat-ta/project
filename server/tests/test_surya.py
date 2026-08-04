import os
from llama_cpp import Llama
from llama_cpp.llama_chat_format import Llava15ChatHandler
import base64

def image_to_base64(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

model_path = "/home/panuwat/project/model/surya/surya-2.gguf"
mmproj_path = "/home/panuwat/project/model/surya/surya-2-mmproj.gguf"

try:
    print("Initializing model...")
    chat_handler = Llava15ChatHandler(clip_model_path=mmproj_path)
    llm = Llama(model_path=model_path, chat_handler=chat_handler, n_ctx=2048, verbose=False)
    
    print("Encoding image...")
    image_b64 = image_to_base64("/home/panuwat/project/test.png")
    
    print("Running inference...")
    response = llm.create_chat_completion(
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{image_b64}"}},
                    {"type": "text", "text": "Extract all text from the image."}
                ]
            }
        ]
    )
    print("Response:", response["choices"][0]["message"]["content"])
except Exception as e:
    print("Error:", e)
