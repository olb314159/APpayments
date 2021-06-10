#' Adds the content of inst/assets/ to polishedpayments/
#'
#' @importFrom shiny addResourcePath registerInputHandler
#'
#' @noRd
#'
.onLoad <- function(...) {
  shiny::addResourcePath("APpayments", system.file("assets", package = "APpayments"))
}
