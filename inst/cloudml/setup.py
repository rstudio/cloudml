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

PIP_INSTALL = [
    # ml-engine doesn't provide TensorFlow 1.3 yet but they could be potentially
    # upgraded; however, we've found out some components (e.g. tfestimators) hang even
    # under python when upgrading TensorFlow versions.
    # ["pip", "install", "tensorflow", "--upgrade"]
]

class CustomCommands(install):
  cache = ""
  config = {}

  """A setuptools Command class able to run arbitrary commands."""
  def RunCustomCommand(self, commands, throws):
    print "Running command: %s" % " ".join(commands)

    process = subprocess.Popen(
        commands,
        stdin  = subprocess.PIPE,
        stdout = subprocess.PIPE,
        stderr = subprocess.STDOUT
    )

    stdout, stderr = process.communicate()
    print "Command output: %s" % stdout
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

  """Retrieves path to cache or empty string."""
  def GetCachePath(self):
    storage = self.config["cloudml"]["storage"]

    cache = storage
    if "cache" in self.config["cloudml"]:
      cache = os.path.join(self.config["cloudml"]["cache"], "python")

    if cache == False:
      cache = ""
    else:
      cache = os.path.join(cache, "cache", "python")

    return cache

  def GetPackagesSource(self):
    return site.getsitepackages()[0]

  def GetTempDir(self, name):
    tempdir = os.path.join(tempfile.gettempdir(), name)
    if not os.path.exists(tempdir):
      os.makedirs(tempdir)
    return tempdir

  """Restores a pip install cache."""
  def RestoreCache(self, destination):
    source = os.path.join(self.cache["path"], "*")
    print "Restoring Python Cache from " + source + " to " + destination

    download = self.GetTempDir("cloudml-python-upload")
    self.RunCustomCommand(["gsutil", "-m", "cp", "-r", source, download], False)

    print "Python Cache Contents: [" + ",".join(os.listdir(download)) + "]"

    for package in os.listdir(download):
      tar_path = os.path.join(download, package)

      print "Restoring from " + tar_path + " into " + destination
      if package.split(".")[-1] == "tar":
        destinationpkg = os.path.join(destination, package.split(".")[0])
        if not os.path.exists(destinationpkg):
          os.makedirs(destinationpkg)
        self.RunCustomCommand(["tar", "-xf", tar_path, "-C", destinationpkg], True)
      else:
        self.RunCustomCommand(["cp", tar_path, destination], True)
      self.cache["files"][os.path.basename(package)] = True


  """Update the pip install cache."""
  def UpdateCache(self, source):
    print "Updating the Python Cache in " + self.cache["path"] + " from " + source

    upload = self.GetTempDir("cloudml-python-upload")

    for package in os.listdir(source):
      if package in self.cache["files"]:
        continue

      packagepath = os.path.join(source, package)

      if not os.path.isdir(packagepath):
        local = packagepath
        target = os.path.join(self.cache["path"], package)
      else:
        local = os.path.join(upload, package + ".tar")
        self.RunCustomCommand(["tar", "-cf", local, "-C", packagepath, "."], True)
        target = os.path.join(self.cache["path"], package + ".tar")

      self.RunCustomCommand(["gsutil", "cp", local, target], True)

  def RunCustomCommandList(self, commands):
    for command in commands:
      self.RunCustomCommand(command, True)

  def run(self):
    distro = platform.linux_distribution()
    print "linux_distribution: %s" % (distro,)

    self.LoadCloudML()

    self.cache = {
      "path": self.GetCachePath(),
      "files": {}
    }

    # Upgrade r if latestr is set in cloudml.yaml
    if (not "latestr" in self.config["cloudml"] or self.config["cloudml"]["latestr"] == True):
      print "Upgrading R"
      self.RunCustomCommandList(UPGRADE_R_COMMANDS)

    # Run custom commands
    self.RunCustomCommandList(CUSTOM_COMMANDS)

    # Only cache new packages
    pipcache = self.GetTempDir("site-packages-cache")
    print "Creating Cache Path: " + pipcache
    with open(os.path.join(site.getsitepackages()[0], "cloudml-cache.pth"), "w") as pathsfile:
      pathsfile.write(pipcache)

    # Restores the pip cache
    # self.RestoreCache(pipcache)

    # Install Keras
    if (not "keras" in self.config["cloudml"] or self.config["cloudml"]["keras"] == True):
      print "Installing Keras"
      pip_install_keras_cmds = map(lambda e : e + ["--target=" + pipcache], PIP_INSTALL_KERAS)
      self.RunCustomCommandList(pip_install_keras_cmds)

    # Run pip install
    pip_install_cmds = map(lambda e : e + ["--target=" + pipcache], PIP_INSTALL)
    self.RunCustomCommandList(pip_install_cmds)

    print "PIP Cache Files: " + ",".join(os.listdir(pipcache))

    # Updates the pip cache
    # self.UpdateCache(pipcache)

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
