import subprocess
import os
import sys
import re

working_dir = sys.argv[1]

files = [os.path.join(working_dir, f) for f in os.listdir(working_dir) if os.path.isfile(os.path.join(working_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]

test_benches = []
modules = []

for f in files:
    match = [line for line in open(f) if re.match(r'module .*\(',line)][0].split(' ')[1].split('(')[0]
    if match.endswith('_tb'):
        test_benches.append(match)
    modules.append(f)

for m in modules:
    print("Compiling " + m)
    subprocess.check_output(['vlog', '-work', 'work',  m])
    #errors_and_warnings = [line for line in open(working_dir + '/transcript') if re.match(r'Errors: [0-9]+ Warnings: [0-9]+', line)]
    #print(errors_and_warnings)

for tb in test_benches:
    cmd = "vsim -c work." + tb + ' -do "run -all"'
    print("Simulating " + tb + " :: " + cmd)
    subprocess.run(["vsim", "-c", "work." + tb, "-do", 'run -all'], stdout=subprocess.DEVNULL)
    #errors_and_warnings = [line for line in open(working_dir + '/transcript') if re.match(r'Errors: [0-9]+ Warnings: [0-9]+', line)]
    #print(errors_and_warnings)

