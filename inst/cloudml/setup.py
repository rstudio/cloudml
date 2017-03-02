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
# Second, if apt-get tool is used then the first command needs to be "apt-get
# update" so the tool refreshes itself and initializes links to download
# repositories.  Without this initial step the other apt-get install commands
# will fail with package not found errors. Note also --assume-yes option which
# shortcuts the interactive confirmation.
#
# The output of custom commands (including failures) will be logged in the
# worker-startup log.

CUSTOM_COMMANDS = [
    # ["apt-key", "adv", "--keyserver", "keyserver.ubuntu.com", "--recv-keys", "E298A3A825C0D65DFD57CBB651716619E084DAB9"],
    # ["add-apt-repository", "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/"],
    ["echo", "deb https://cloud.r-project.org/bin/linux/debian jessie-cran3/", ">>", "/etc/apt/sources.list"],
    ["apt-key", "adv", "--keyserver", "keys.gnupg.net", "--recv-key", "6212B7B7931C4BB16280BA1306F90DE5381BA480"],
    # ["apt-get", "clean"],
    # ["rm", "-rf", "/var/lib/apt/lists/*"],
    # ["rm", "-rf", "/var/lib/apt/lists/partial/*"],
    # ["apt-get", "clean"],
    ["apt-get", "-qq", "-m", "-y", "update"],
    ["apt-get", "-qq", "-m", "-y", "upgrade"],
    ["apt-get", "-qq", "-m", "-y", "install", "libcurl4-openssl-dev", "libxml2-dev", "libxslt-dev", "libssl-dev", "r-base", "r-base-dev"]
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

    stdout, stderr = process.communicate
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
    package_data     = {"": ["*.r", "*.R", "config.yml"]},
    description      = "RStudio Integration",
    requires         = [],
    cmdclass         = { "install": CustomCommands }
)

#if __name__ == "__main__":
#  setup(name="introduction", packages=["introduction"])
