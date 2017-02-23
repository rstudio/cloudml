# Deploy an R application to 'cloudml'.
import subprocess
import sys
import os

# Determine path to entrypoint.
path, filename = os.path.split(os.path.realpath(__file__))
entrypoint = os.path.realpath(path + "/app.R")
if not os.path.exists(entrypoint):
  raise IOError("Entrypoint '" + entrypoint + "' does not exist.")

# Move to directory for entrypoint.
os.chdir(path)

print "Running application with entrypoint: %s" % (entrypoint, )
print "Using working directory: %s" % (path, )

# Construct command to be called, and append command line arguments.
commands = ["Rscript", entrypoint]
for x in sys.argv[1:]:
  commands.append(x)

process = subprocess.Popen(
  commands,
  stdin  = subprocess.PIPE,
  stdout = subprocess.PIPE,
  stderr = subprocess.STDOUT
)

stdout, stderr = process.communicate()

if stdout is not None: print stdout
if stderr is not None: print stderr

if process.returncode != 0:
  fmt = "Command %s failed: exit code %s"
  print fmt % (commands, process.returncode)
else:
  print "Command %s ran successfully." % (commands, )
