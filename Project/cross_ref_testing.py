import subprocess
import os
import sys
import re

src_dir = sys.argv[1] # src directory should be theo_code, Scott_proj_code, ethan_code, or ZachCode
# test bench directory is ./Project/test_benches
bench_dir = "./Project/test_benches/"

src = [os.path.join(src_dir, f) for f in os.listdir(src_dir) if os.path.isfile(os.path.join(src_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]
benches = [os.path.join(bench_dir, f) for f in os.listdir(bench_dir) if os.path.isfile(os.path.join(bench_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]

test_benches = []
modules = []

# read all source files
for s in src:
    match = [line for line in open(f) if re.match(r'module .*\(',line)][0].split(' ')[1].split('(')[0]
    modules.append(s)

# read all test bench files
for tb in benches:
    match = [line for line in open(f) if re.match(r'module .*\(',line)][0].split(' ')[1].split('(')[0]
    test_benches.append(tb)

# compile all source files
for m in modules:
    print("Compiling " + m)
    subprocess.check_output(['vlog', '-work', 'work',  m])

# compile all test benches
for tb in test_benches:
    print("Compiling " + tb)
    subprocess.check_output(['vlog', '-work', 'work',  tb])

# test each test bench
for tb in test_benches:
    cmd = "vsim -c work." + tb + ' -do "run -all"'
    print("Simulating " + tb + " :: " + cmd)
    subprocess.run(["vsim", "-c", "work." + tb, "-do", 'run -all'], stdout=subprocess.DEVNULL)

