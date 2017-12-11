from setuptools import setup

import os
import platform
import site
import subprocess
import tempfile
import yaml

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

UPGRADE_R_COMMANDS = [
    # Upgrade R
    ["apt-get", "-qq", "-m", "-y", "update"],
    ["apt-key", "adv", "--keyserver", "keyserver.ubuntu.com", "--recv-keys", "E298A3A825C0D65DFD57CBB651716619E084DAB9"],
    ["apt-get", "-qq", "-m", "-y", "install", "software-properties-common", "apt-transport-https"],
    ["add-apt-repository", "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/"],
]

CUSTOM_COMMANDS = [
    # Update repositories
    ["apt-get", "-qq", "-m", "-y", "update"],

    # Upgrading packages could be useful but takes about 30-60s additional seconds
    # ["apt-get", "-qq", "-m", "-y", "upgrade"],

    # Install R dependencies
    ["apt-get", "-qq", "-m", "-y", "install", "libcurl4-openssl-dev", "libxml2-dev", "libxslt-dev", "libssl-dev", "r-base", "r-base-dev"],
]

PIP_INSTALL_KERAS = [
    # Install keras
    ["pip", "install", "keras", "--upgrade"],

    # Install additional keras dependencies
    ["pip", "install", "h5py", "pyyaml", "requests", "Pillow", "scipy", "--upgrade"]
]

class CustomCommands(install):
  cache = ""
  config = {}

  """A setuptools Command class able to run arbitrary commands."""
  def RunCustomCommand(self, commands, throws):
    print("Running command: %s" % " ".join(commands))

    process = subprocess.Popen(
        commands,
        stdin  = subprocess.PIPE,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT
    )

    stdout, stderr = process.communicate()
    print("Command output: %s" % stdout)
    status = process.returncode
    if throws and status != 0:
      message = "Command %s failed: exit code %s" % (commands, status)
      raise RuntimeError(message)

  """Loads the cloudml.yml config"""
  def LoadCloudML(self):
    path, filename = os.path.split(os.path.realpath(__file__))
    cloudmlpath = os.path.join(path, "cloudml-model", "cloudml.yml")
    stream = open(cloudmlpath, "r")
    self.config = yaml.load(stream)

  """Runs a list of arbitrary commands"""
  def RunCustomCommandList(self, commands):
    for command in commands:
      self.RunCustomCommand(command, True)

  def run(self):
    distro = platform.linux_distribution()
    print("linux_distribution: %s" % (distro,))

    self.LoadCloudML()

    # Upgrade r if latestr is set in cloudml.yaml
    if (not "latestr" in self.config["cloudml"] or self.config["cloudml"]["latestr"] == True):
      print("Upgrading R")
      self.RunCustomCommandList(UPGRADE_R_COMMANDS)

    # Run custom commands
    self.RunCustomCommandList(CUSTOM_COMMANDS)

    # Run pip install
    if (not "keras" in self.config["cloudml"] or self.config["cloudml"]["keras"] == True):
      print("Installing Keras")
      self.RunCustomCommandList(PIP_INSTALL_KERAS)

    # Run regular install
    install.run(self)

REQUIRED_PACKAGES = []

setup(
    name             = "cloudml",
    version          = "1.0.0.0",
    author           = "Author",
    author_email     = "author@example.com",
    install_requires = REQUIRED_PACKAGES,
    packages         = find_packages(),
    package_data     = {"": ["*"]},
    description      = "RStudio Integration",
    requires         = [],
    cmdclass         = { "install": CustomCommands }
)
