#!/usr/bin/env python
import os
import runpy
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
runpy.run_path(os.path.join(ROOT, "common", "scripts", "reindex_helper.py"), run_name="__main__")
