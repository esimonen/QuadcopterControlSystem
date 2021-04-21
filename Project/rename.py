import subprocess
import os
import sys
import re

working_dir = sys.argv[1]
name = sys.argv[2]

files = [os.path.join(working_dir, f) for f in os.listdir(working_dir) if os.path.isfile(os.path.join(working_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]

# test_benches = []
# modules = []

for f in files:
    match = [line for line in open(f) if re.match(r'module .*\(',line)][0].split(' ')[1].split('(')[0]
    # modules.append(f)
    subprocess.run(["mv", f, name + '_' + f], stdout=subprocess.DEVNULL)