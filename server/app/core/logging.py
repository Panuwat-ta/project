import logging
import json
from datetime import datetime
from app.core.config import TH_TIMEZONE

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": datetime.now(TH_TIMEZONE).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        
        if hasattr(record, "request_id"):
            log_record["request_id"] = record.request_id
            
        if record.exc_info:
            log_record["exc_info"] = self.formatException(record.exc_info)
            
        return json.dumps(log_record)

def setup_logging():
    # Only format app specific logs as JSON to prevent noise
    logger = logging.getLogger("app")
    logger.setLevel(logging.INFO)
    
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    
    # Remove existing handlers
    for h in logger.handlers[:]:
        logger.removeHandler(h)
        
    logger.addHandler(handler)
    
    # also set for root logger if desired, but here we just do "app" and "uvicorn.access"
    return logger

logger = setup_logging()
