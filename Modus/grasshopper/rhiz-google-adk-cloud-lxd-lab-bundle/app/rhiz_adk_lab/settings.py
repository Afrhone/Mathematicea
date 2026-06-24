from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', extra='ignore')
    agent_gateway_port: int = 8099
    llama_gpu_openai_base_url: str = 'http://192.168.0.125:8089/v1'
    llama_gpu_ollama_base_url: str = 'http://192.168.0.125:11435'
    gpu_compute_openai_base_url: str = 'http://192.168.0.52:8080/v1'
    default_model: str = 'llama-3.2-3b'
    provider_order: str = 'llama_gpu_openai,gpu_compute_openai,google_adk'
    google_cloud_project: str = ''
    google_cloud_region: str = 'europe-west6'
    gemini_model: str = 'gemini-2.5-flash'

settings = Settings()
