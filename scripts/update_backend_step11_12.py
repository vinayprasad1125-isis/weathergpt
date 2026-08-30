import os
import re

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

# 1. Update app/main.py
main_file = os.path.join(base_dir, 'app/main.py')
with open(main_file, 'r') as f:
    main_content = f.read()

if 'climate_router' not in main_content:
    main_content = main_content.replace(
        'from app.api.routes.advisory import router as advisory_router',
        'from app.api.routes.advisory import router as advisory_router\\nfrom app.api.routes.climate import router as climate_router\\nfrom app.db.database import engine, Base'
    )
    
    # Add table creation to lifespan/startup. FastAPI usually has @app.on_event("startup")
    startup_block = '''@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
'''
    if '@app.on_event("startup")' not in main_content:
        main_content = main_content.replace('app = FastAPI', startup_block + '\\napp = FastAPI')
        
    main_content = main_content.replace(
        'app.include_router(advisory_router, prefix="/api/v1/advisory", tags=["Advisory"])',
        'app.include_router(advisory_router, prefix="/api/v1/advisory", tags=["Advisory"])\\napp.include_router(climate_router, prefix="/api/v1/climate", tags=["Climate"])'
    )
    with open(main_file, 'w') as f:
        f.write(main_content)

# 2. Update app/schemas/chat.py
chat_schema_file = os.path.join(base_dir, 'app/schemas/chat.py')
with open(chat_schema_file, 'r') as f:
    chat_content = f.read()

if 'language: str' not in chat_content:
    chat_content = chat_content.replace(
        'location: Optional[LocationInput] = None',
        'location: Optional[LocationInput] = None\\n    language: str = "auto"'
    )
    with open(chat_schema_file, 'w') as f:
        f.write(chat_content)

print("Backend main and schemas updated.")
