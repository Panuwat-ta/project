import uuid
from contextvars import ContextVar
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

request_id_context = ContextVar("request_id", default=None)

class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        req_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request_id_context.set(req_id)
        
        # We could inject this into python logging via a filter, 
        # but for simplicity, we attach it to request state as well
        request.state.request_id = req_id
        
        response = await call_next(request)
        response.headers["X-Request-ID"] = req_id
        return response
