# Deploy an R application to Google Cloud, using the 'cloudml' package.
import subprocess
import sys
import os

# Extract command line arguments.
entrypoint = sys.argv[1]
config     = sys.argv[2]

# Set up environment.
os.environ["R_CONFIG_ACTIVE"] = config

# Construct absolute path to entrypoint.
path, filename = os.path.split(os.path.realpath(__file__))
entrypoint = os.path.realpath(path + "/" + entrypoint)
if not os.path.exists(entrypoint):
  raise IOError("Entrypoint '" + entrypoint + "' does not exist.")

# Move to directory for entrypoint.
os.chdir(path)

print "Running application with entrypoint: %s" % (entrypoint, )
print "Using working directory: %s" % (path, )

# Run 'Rscript' with this entrypoint.
commands = ["Rscript", entrypoint]

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
