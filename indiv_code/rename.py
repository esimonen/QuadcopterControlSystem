# this code is kinda messed up, needs to be run from the Project directory
import subprocess
import os
import sys
import re

working_dir = sys.argv[1]
name = sys.argv[2]

files = [os.path.join(working_dir, f) for f in os.listdir(working_dir) if os.path.isfile(os.path.join(working_dir, f)) and (os.path.splitext(f)[1] == '.sv' or os.path.splitext(f)[1] == '.v')]
for f in files: 
    subprocess.run(["mv", f, f.split('/')[0] + '/' + f.split('/')[1] + '/' + name + '_' + f.split('/')[2]])