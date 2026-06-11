import asyncpg
from app.config import DATABASE_URL, HISTORY_LIMIT


async def create_pool() -> asyncpg.Pool:
    return await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)


async def init_db(pool: asyncpg.Pool) -> None:
    async with pool.acquire() as conn:
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS messages (
                id         BIGSERIAL PRIMARY KEY,
                role       TEXT        NOT NULL,
                content    TEXT        NOT NULL,
                user_id    TEXT        NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
        """)


async def fetch_history(pool: asyncpg.Pool, userId: str) -> list[dict]:
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT role, content
            FROM (
                SELECT role, content, user_id, created_at
                FROM messages
                WHERE user_id = $1
                ORDER BY created_at DESC
                LIMIT $1
            ) sub
            ORDER BY created_at ASC
        """, HISTORY_LIMIT)
    return [{"role": r["role"], "content": r["content"]} for r in rows]


async def save_message(pool: asyncpg.Pool, role: str, content: str, userId: str) -> None:
    async with pool.acquire() as conn:
        await conn.execute(
            "INSERT INTO messages (role, content, user_id) VALUES ($1, $2, $3)",
            role, content, userId
        )