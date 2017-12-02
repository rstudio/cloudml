from setuptools import setup

import platform
import subprocess
from setuptools import find_packages
from setuptools import setup
from setuptools.command.install import install

# Some custom command to run during setup. Typically, these commands will
# include steps to install non-Python packages
#
# First, note that there is no need to use the sudo command because the setup
# script runs with appropriate access.
#
# Second, if apt-get tool is used then the first command needs to be "apt-get
# update" so the tool refreshes itself and initializes links to download
# repositories.  Without this initial step the other apt-get install commands
# will fail with package not found errors. Note also --assume-yes option which
# shortcuts the interactive confirmation.
#
# The output of custom commands (including failures) will be logged in the
# worker-startup log.

CUSTOM_COMMANDS = [
    # Update repositories
    ["apt-get", "-qq", "-m", "-y", "update"],

    # Upgrading packages could be useful but takes about 30-60s additional seconds
    # ["apt-get", "-qq", "-m", "-y", "upgrade"],

    # Install R + dependencies
    ["apt-get", "-qq", "-m", "-y", "install", "libcurl4-openssl-dev", "libxml2-dev", "libxslt-dev", "libssl-dev", "r-base", "r-base-dev"],

    # Install keras
    ["pip", "install", "keras", "--upgrade"],

    # Install additional keras dependencies
    ["pip", "install", "h5py", "pyyaml", "requests", "Pillow", "scipy", "--upgrade"]

    # ml-engine doesn't provide TensorFlow 1.3 yet but they could be potentially
    # upgraded; however, we've found out some components (e.g. tfestimators) hang even
    # under python when upgrading TensorFlow versions.
    # ["pip", "install", "tensorflow", "--upgrade"]
]

class CustomCommands(install):

  """A setuptools Command class able to run arbitrary commands."""
  def RunCustomCommand(self, commands):

    process = subprocess.Popen(
        commands,
        stdin  = subprocess.PIPE,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT
    )

    stdout, stderr = process.communicate()
    print "Command output: %s" % stdout
    status = process.returncode
    if status != 0:
      message = "Command %s failed: exit code %s" % (commands, status)
      raise RuntimeError(message)

  def run(self):
    distro = platform.linux_distribution()
    print "linux_distribution: %s" % (distro,)

    # Run custom commands
    for command in CUSTOM_COMMANDS:
      self.RunCustomCommand(command)

    # Run regular install
    install.run(self)

REQUIRED_PACKAGES = []

setup(
    name             = "cloudml",
    version          = "0.0.0.1",
    author           = "Google and RStudio",
    author_email     = "kevin@rstudio.com",
    install_requires = REQUIRED_PACKAGES,
    packages         = find_packages(),
    package_data     = {"": ["*"]},
    description      = "RStudio Integration",
    requires         = [],
    cmdclass         = { "install": CustomCommands }
)

#if __name__ == "__main__":
#  setup(name="introduction", packages=["introduction"])
