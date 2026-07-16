import types
import sys
import importlib.machinery
import inspect
import pkgutil

class DummyExt(types.ModuleType):
    def __getattr__(self, name):
        if name.startswith('__') and name.endswith('__'):
            raise AttributeError(name)
        def dummy_func(*args, **kwargs):
            raise RuntimeError(f"mmcv._ext is missing. Cannot call {name}")
        return dummy_func

mock_ext = DummyExt('mmcv._ext')
mock_ext.__spec__ = importlib.machinery.ModuleSpec('mmcv._ext', None)
sys.modules['mmcv._ext'] = mock_ext

print("Loader:", pkgutil.find_loader('mmcv._ext'))
print("File:", getattr(mock_ext, '__file__', None))
print("inspect file:", inspect.getfile(mock_ext) if hasattr(mock_ext, '__file__') else "No file")

