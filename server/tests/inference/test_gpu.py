import onnxruntime as ort
from llama_cpp import Llama

print("ONNX Runtime Providers:", ort.get_available_providers())

print("Imported Llama successfully. GPU is enabled if you see 'CUDA_Execution_Provider' above.")
