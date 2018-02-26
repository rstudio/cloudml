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

CUSTOM_COMMANDS = {
    "ubuntu": [
        # Upgrade R
        ["apt-get", "-qq", "-m", "-y", "update"],
        ["apt-key", "adv", "--keyserver", "keyserver.ubuntu.com", "--recv-keys", "E298A3A825C0D65DFD57CBB651716619E084DAB9"],
        ["apt-get", "-qq", "-m", "-y", "install", "software-properties-common", "apt-transport-https"],
        ["add-apt-repository", "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/"],

        # Update repositories
        ["apt-get", "-qq", "-m", "-y", "update"],

        # Upgrading packages could be useful but takes about 30-60s additional seconds
        # ["apt-get", "-qq", "-m", "-y", "upgrade"],

        # Install R dependencies
        ["apt-get", "-qq", "-m", "-y", "install", "libcurl4-openssl-dev", "libxml2-dev", "libxslt-dev", "libssl-dev", "r-base", "r-base-dev"],
    ],
    "debian": [
        # Upgrade R
        ["touch", "/etc/apt/sources.list"],
        ["sed", "-i", "$ a\deb http://cran.rstudio.com/bin/linux/debian stretch-cran34/", "/etc/apt/sources.list"],
        ["cat", "/etc/apt/sources.list"],
        ["apt-key", "adv", "--keyserver", "keys.gnupg.net", "--recv-key", "E19F5F87128899B192B1A2C2AD5F960A256A04AF"],

        # Update repositories
        ["apt-get", "-qq", "-m", "-y", "update", "--fix-missing"],

        # Upgrading packages could be useful but takes about 30-60s additional seconds
        ["apt-get", "-qq", "-m", "-y", "upgrade"],

        # Install R dependencies
        ["apt-get", "-qq", "-m", "-y", "install", "libcurl4-openssl-dev", "libxml2-dev", "libxslt-dev", "libssl-dev"],

        ["apt-get", "-qq", "-m", "-y", "update", "--fix-missing"],

        ["apt-get", "-qq", "-m", "-y", "clean"],
        ["apt-get", "-qq", "-m", "-y", "autoclean"],

        ["apt-get", "-qq", "-m", "-y", "install", "aptitude"],
        ["aptitude", "--assume-yes", "install", "r-base"],
        ["aptitude", "--assume-yes", "install", "r-base-dev"]
    ]
}

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

  """Loads the job.yml config which is used to pass internal settings to cloudml jobs"""
  def LoadJobConfig(self):
    path, filename = os.path.split(os.path.realpath(__file__))
    cloudmlpath = os.path.join(path, "cloudml-model", "job.yml")
    if (not os.path.isfile(cloudmlpath)):
      raise ValueError('job.yml expected in job bundle but is missing')

    stream = open(cloudmlpath, "r")
    self.config = yaml.load(stream)

  """Runs a list of arbitrary commands"""
  def RunCustomCommandList(self, commands):
    for command in commands:
      self.RunCustomCommand(command, True)

  def run(self):
    distro = platform.linux_distribution()
    print("linux_distribution: %s" % (distro,))

    distro_key = distro[0].lower()
    if (not distro_key in CUSTOM_COMMANDS.keys()):
      raise ValueError("'" + distro[0] + "' is currently not supported, please report this under github.com/rstudio/cloudml/issues")
    custom_os_commands = CUSTOM_COMMANDS[distro_key]

    self.LoadJobConfig()

    # Run custom commands
    self.RunCustomCommandList(custom_os_commands)

    # Run pip install
    if (not "keras" in self.config or self.config["keras"] == True):
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
