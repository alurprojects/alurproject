import logging
from typing import Optional
from langchain_core.language_models.chat_models import BaseChatModel
from app.core.config import settings

logger = logging.getLogger(__name__)


def get_primary_llm() -> Optional[BaseChatModel]:
    """Returns Gemini chat model if API key is present."""
    if settings.GEMINI_API_KEY:
        try:
            from langchain_google_genai import ChatGoogleGenerativeAI

            return ChatGoogleGenerativeAI(
                model="gemini-1.5-flash",
                google_api_key=settings.GEMINI_API_KEY,
                temperature=0.1,
            )
        except Exception as e:
            logger.warning(f"Failed to initialize Gemini LLM: {e}")
    return None


def get_fallback_llm() -> Optional[BaseChatModel]:
    """Returns Groq chat model as fallback."""
    if settings.GROQ_API_KEY:
        try:
            from langchain_groq import ChatGroq

            return ChatGroq(
                model="llama-3.3-70b-versatile",
                groq_api_key=settings.GROQ_API_KEY,
                temperature=0.1,
            )
        except Exception as e:
            logger.warning(f"Failed to initialize Groq LLM: {e}")
    return None


def get_llm() -> BaseChatModel:
    """Returns primary LLM (Gemini) or fallback LLM (Groq).

    Raises RuntimeError if neither provider is available.
    """
    primary = get_primary_llm()
    if primary:
        return primary

    fallback = get_fallback_llm()
    if fallback:
        return fallback

    raise RuntimeError("No LLM provider configured. Please provide GEMINI_API_KEY or GROQ_API_KEY.")
