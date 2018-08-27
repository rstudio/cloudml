# cloudml 0.6.0 (unreleased)

- Fixed `gcloud_install()` to properly execute `gcloud init` in RStudio
  terminal under OS X (#177).

- Fixed `gs_rsync()` to avoid creating a local destination directory when 
  destination uses remote storage (#172).

- Improved terminal support in Windows to launch by default correct shell.

# cloudml 0.5.1

- Added support for `dry_run` in `cloudml_train`.

- Fixed CRAN results for cloudml.

- Fixed packrat package missing error (#168).

# cloudml 0.5.0

- First release to CRAN.
