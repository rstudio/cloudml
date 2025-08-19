
# package globals
.__JOB_REGISTRY__. <- new.env(parent = emptyenv())


#' Interface to the Google Cloud Machine Learning Platform
#'
#' @description
#'
#' The **cloudml** package provides an R interface to [Google Cloud Machine
#' Learning Engine](https://cloud.google.com/vertex-ai), a managed service that
#' enables:
#'
#' * Scalable training of models built with the
#' [keras](https://keras3.posit.co/),
#' [tfestimators](https://github.com/rstudio/tfestimators), and
#' [tensorflow](https://tensorflow.rstudio.com/) R packages.
#'
#' * On-demand access to training on GPUs, including the new [Tesla P100
#' GPUs](https://www.nvidia.com/en-us/data-center/) from NVIDIA&reg;.
#'
#' * Hyperparameter tuning to optimize key attributes of model architectures in
#' order to maximize predictive accuracy.
#'
#' * Deployment of trained models to the Google global prediction platform that
#' can support thousands of users and TBs of data.
#'
#' @details
#'
#' CloudML is a managed service where you pay only for the hardware resources
#' that you use. Prices vary depending on configuration (e.g. CPU vs. GPU vs.
#' multiple GPUs). See <https://cloud.google.com/vertex-ai/pricing> for
#' additional details.
#'
#' For documentation on using the R interface to CloudML see the package website
#' at <https://github.com/rstudio/cloudml>
#'
#' @references <https://github.com/rstudio/cloudml>
#' @name cloudml-package
#' @aliases cloudml
#' @keywords internal
"_PACKAGE"
