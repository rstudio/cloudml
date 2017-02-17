# Deploy an R application to 'cloudml'.
import subprocess
import sys
import os

path, filename = os.path.split(os.path.realpath(__file__))

entrypoint = os.path.realpath(path + "/../app.R")
commands = ["Rscript", entrypoint]
for x in sys.argv[1:]: commands.append(x)

process = subprocess.Popen(
  commands,
  stdin = subprocess.PIPE,
  stdout = subprocess.PIPE,
  stderr = subprocess.STDOUT
)

stdout, stderr = process.communicate()

print stdout
print stderr

if process.returncode != 0:
  fmt = "Command %s failed: exit code %s"
  print fmt % (commands, process.returncode)
