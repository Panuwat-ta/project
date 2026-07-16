import types
import sys
import importlib.machinery
import pkgutil

class DummyExt(types.ModuleType):
    def __getattr__(self, name):
        def dummy_func(*args, **kwargs):
            raise RuntimeError(f"mmcv._ext is missing. Cannot call {name}")
        return dummy_func

mock_ext = DummyExt('mmcv._ext')
mock_ext.__spec__ = importlib.machinery.ModuleSpec('mmcv._ext', None)
sys.modules['mmcv._ext'] = mock_ext

print(pkgutil.find_loader('mmcv._ext'))
