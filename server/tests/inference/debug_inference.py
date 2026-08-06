import asyncio
from app.services.inference_service import InferenceService

async def main():
    service = InferenceService()
    
    with open("uploads/397c3d3d83aaa48ac18e8875341f06ddff763226429242c58b9855cc5a1917c7.png", "rb") as f:
        img_bytes = f.read()
        
    result = service.predict(img_bytes)
    
    heatmap_bytes = result.get("heatmap_bytes")
    if heatmap_bytes:
        print("Heatmap generated! Size:", len(heatmap_bytes))
        with open("uploads/heatmaps/test_debug.jpg", "wb") as out:
            out.write(heatmap_bytes)
    else:
        print("No heatmap bytes returned!")
        
if __name__ == "__main__":
    asyncio.run(main())
