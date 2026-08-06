import asyncio
import base64
from app.services.inference_service import InferenceService

async def main():
    from app.services.inference_service import inference_service as service
    
    with open("uploads/397c3d3d83aaa48ac18e8875341f06ddff763226429242c58b9855cc5a1917c7.png", "rb") as f:
        img_bytes = f.read()
    
    print("Running Surya OCR alone (if we just call it directly)...")
    image_b64 = base64.b64encode(img_bytes).decode('utf-8')
    response = service.llm.create_chat_completion(
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_b64}"}},
                    {"type": "text", "text": "Extract all text from the image."}
                ]
            }
        ]
    )
    print("Response:", response["choices"][0]["message"]["content"])

if __name__ == "__main__":
    asyncio.run(main())
