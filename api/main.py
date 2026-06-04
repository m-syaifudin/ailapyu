from contextlib import asynccontextmanager
from fastapi import FastAPI

from app.database import create_pool, init_db
from app.routers.chat import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool = await create_pool()
    await init_db(pool)
    app.state.pool = pool
    yield
    await pool.close()


app = FastAPI(title="ailapyu", lifespan=lifespan)
app.include_router(router)