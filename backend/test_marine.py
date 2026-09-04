import asyncio
from app.services.ai_query_service import AIQueryService
from app.schemas.chat import ChatRequest

async def main():
    service = AIQueryService()
    print("=== TEST: Route Query ===")
    req1 = ChatRequest(message="Is it safe to travel from Chennai to Delhi by boat?")
    resp1 = await service.process_chat(req1)
    print(resp1.message)
    
    print("\n=== TEST: Tomorrow Marine ===")
    req2 = ChatRequest(message="I am a fisherman in Chennai, what is the wave height and is it safe to go out tomorrow?")
    resp2 = await service.process_chat(req2)
    print(resp2.message)
    
    await service.close()

if __name__ == "__main__":
    asyncio.run(main())
