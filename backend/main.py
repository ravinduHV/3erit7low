import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.auth.router import router as auth_router
from src.scouts.router import router as scouts_router
from src.admin.router import router as admin_router
from src.progress.router import router as progress_router
from src.assistant.router import router as assistant_router

app = FastAPI(
    title="Colorful Adventures - Scout Progress API",
    description="Backend API for managing scout syllabi, tracking progress, and running rule-based assistant tips.",
    version="1.0.0",
    redirect_slashes=False,
)

# Set up CORS. Allow all for easy flutter client integration (web, mobile, emulator)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers under /v1 prefix
app.include_router(auth_router, prefix="/v1")
app.include_router(scouts_router, prefix="/v1")
app.include_router(admin_router, prefix="/v1")
app.include_router(progress_router, prefix="/v1")
app.include_router(assistant_router, prefix="/v1")

@app.get("/")
async def root():
    return {
        "app": "Colorful Adventures - Scout Progress App API",
        "status": "online",
        "version": "1.0.0",
        "documentation": "/docs"
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
