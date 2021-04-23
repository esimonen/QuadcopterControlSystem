import subprocess
import os
import sys
import re

src_dir = sys.argv[1] # src directory should be theo_code, Scott_proj_code, ethan_code, or ZachCode
# test bench directory is ./Project/test_benches
bench_dir = "test_benches/"

src = [os.path.join(src_dir, f) for f in os.listdir(src_dir) if os.path.isfile(os.path.join(src_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]
benches = [os.path.join(bench_dir, f) for f in os.listdir(bench_dir) if os.path.isfile(os.path.join(bench_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]

test_benches = []
modules = []

## read all source files
#for s in src:
#    match = [line for line in open(s) if re.match(r'module .*\(',line)][0].split(' ')[1].split('(')[0]
#    modules.append(s)

# read all test bench files
for tb in benches:
    lines = [line for line in open(tb) if re.match(r'module .*\(',line)]
    if lines: # check here bc tb_tasks doesn't follow regex
        test_benches.append(lines[0].split(' ')[1].split('(')[0])

#print(test_benches);
#exit()

# compile all source files
subprocess.check_output(['vlog' , '-work', 'work', os.path.join(src_dir, '*.sv')])
# compile tasks
subprocess.check_output(['vlog', '-work' , 'work', './test_benches/*_tb_tasks.sv'])

# compile all test benches
subprocess.check_output(['vlog', '-work', 'work', os.path.join(bench_dir, '*.sv')])

# test each test bench
for tb in test_benches:
    cmd = "vsim -c work." + tb + ' -do "run -all"'
    print("Simulating " + tb + " :: " + cmd)
    subprocess.run(["vsim", "-c", "work." + tb, "-do", 'run -all'])#, stdout=subprocess.DEVNULL)

