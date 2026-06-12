from fastapi import HTTPException, Request

# A simple, zero-RAM cost protection array
BANNED_KEYWORDS = ["drop table", "ignore previous instructions", "system prompt", "hack"]

async def check_prompt_guardrails(user_message: str):
    # 1. Structural Validation
    # if len(user_message) > 2000: # Protect against buffer/token flooding
    #     raise HTTPException(status_code=400, detail="Prompt too long.")
        
    # 2. String Injection Checking
    lower_message = user_message.lower()
    for keyword in BANNED_KEYWORDS:
        if keyword in lower_message:
            raise HTTPException(status_code=400, detail="Inappropriate or malicious prompt detected.")
            
    return True