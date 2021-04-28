import subprocess
import os
import sys
import re
from datetime import datetime

src_dir = sys.argv[1] # src directory should be theo_code, Scott_proj_code, ethan_code, or ZachCode
# test bench directory is ./Project/test_benches
bench_dir = "../test_benches/"

src = [os.path.join(src_dir, f) for f in os.listdir(src_dir) if os.path.isfile(os.path.join(src_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]
benches = [os.path.join(bench_dir, f) for f in os.listdir(bench_dir) if os.path.isfile(os.path.join(bench_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]

test_benches = []
modules = []

# read all test bench files
for tb in benches:
    lines = [line for line in open(tb) if re.match(r'module .*\(',line)]
    if lines: # check here bc tb_tasks doesn't follow regex
        test_benches.append(lines[0].split(' ')[1].split('(')[0])

# compile all source files
subprocess.check_output(['vlog' , '-work', 'work', '+cover', '+acc',  os.path.join(src_dir, '*.sv')])

# compile all test benches
subprocess.check_output(['vlog', '-work', 'work', "+acc",  os.path.join(bench_dir, '*.sv')])

now_str = datetime.now().strftime("%Y/%m/%d/%H/%M/%S")
subprocess.run(["mkdir", "-p", now_str])

# run tests with coverage
for tb in test_benches:
    subprocess.run(["vsim", "-c", "-coverage", "work." + tb, "-voptargs=+acc", "-do", 'coverage save -onexit -assert -directive -cvg -codeAll ./' + now_str + '/' + tb + '_cvg.ucdb; run -all; exit'], stdout=subprocess.DEVNULL)

merged_res_file = "./" + now_str + "/suite_cvg.ucdb"

subprocess.run(["vsim", "-c", "-do", "vcover merge " + merged_res_file + " ./" + now_str + "/*.ucdb; exit"], stdout=subprocess.DEVNULL)
subprocess.run(["vsim", "-c", "-viewcov", merged_res_file, "-do", "coverage analyze -du *; exit"])
