from contextlib import asynccontextmanager
from fastapi import FastAPI

from app.database import create_pool, init_db
from app.routers.chat import router

from fastapi.middleware.cors import CORSMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await create_pool()
    await init_db(pool)
    app.state.pool = pool
    yield
    await pool.close()


app = FastAPI(title="ailapyu", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)