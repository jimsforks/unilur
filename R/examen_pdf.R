#' Convert to an examen PDF document
#'
#' Format for converting from R Markdown to an examen PDF document.
#' 
#' @inheritParams rmarkdown::pdf_document
#' 
#' @inheritParams rmarkdown::latex_document
#' 
#' @details See the inherited `rmarkdown::pdf_document` help page for additional arguments.
#' 
#' @param solution Turn ON or OFF the rendering of solution chunks (default is \code{FALSE})
#' 
#' @param suffix Suffix which is added to the filename (default is '_question' for 'unilur::examen_pdf' and '_solution' for 'unilur::examen_pdf_solution')
#' 
#' @param id Draw a student identification box
#' 
#' @param mcq Theme for the multiple choice questions (\code{oneparchoices}, \code{oneparchoicesalt}, \code{oneparcheckboxesalt} or \code{oneparcheckboxes})
#' 
#' @return R Markdown output format to pass to \code{\link[rmarkdown]{render}}
#' 
#' @export
examen_pdf <- function(
  solution = FALSE,
  suffix = "_question",
  id = FALSE,
  mcq = "oneparchoices",
  includes = NULL,
  pandoc_args = NULL,
  ...
) {
  pandoc_args <- c(pandoc_args, "--variable", "documentclass=exam")
  
  # Using the exam class and passing an additional exam variable to the pandoc template
  pandoc_args <- c(pandoc_args, "--variable", "exam=yes")
  
  includes_examen <- list(in_header = system.file("rmd", "examen_pdf", "mcq.tex",
                                                  package = "unilur"))
  
  if (isTRUE(id)) includes_examen <- c(includes_examen,
                                       list(
                                         before_body = system.file("rmd", "examen_pdf", "idbox.tex",
                                                                   package = "unilur")
                                       )
  )
  
  format <- tutorial_pdf(solution = solution,
                         suffix = suffix,
                         pandoc_args = pandoc_args,
                         includes = merge_includes(includes_examen, includes),
                         ...)
  
  hook_chunk <- format$knitr$knit_hooks$chunk
  
  format$knitr$knit_hooks$chunk <- function(x, options) {
    # If the "mcq" option is set we override the itemize environment
    if (isTRUE(options[["mcq"]])) x <- itemize2mcq(x, mcq.option = mcq, ifelse(is.numeric(options$mcq.n), options$mcq.n, 3))
    hook_chunk(x, options)
  }
  
  format
}

# "itemize2mcq" function
# Called by hook_chunk if the mcq option is set
# Wraps the chunk with a start and stop macro to enable/disable an alternative itemize environment
itemize2mcq <- function(x, mcq.option = c("oneparchoices", "oneparchoicesalt", "oneparcheckboxesalt", "oneparcheckboxes"), per.line = 3) {
  # mcq.options contains a list of the yaml mcq options and the corresponding
  # latex macros
  mcq.option <- match.arg(mcq.option)
  
  if (is.numeric(per.line)) MCQMacroOption <- paste0("[", per.line, "]")
  
  MCQMacros <- list(oneparchoices = c("opc", ""),
                    oneparchoicesalt = c("opcalt", MCQMacroOption),
                    oneparcheckboxesalt = c("opcbalt", MCQMacroOption),
                    oneparcheckboxes = c("opcb", "")) #,
  #checkboxes = c("cb", ""), # Disabling the two last options as they generate latex errors...
  #choices = c("ch", ""))    # TODO: Fix it!
  
  mcq.start <- paste0("\n\\", MCQMacros[[mcq.option]][1], MCQMacros[[mcq.option]][2], "{on}\n")
  mcq.end <- paste0("\n\\", MCQMacros[[mcq.option]][1], "{off}\n")
  return(paste(c(mcq.start, x, mcq.end), collapse = "\n"))
}

#' @rdname examen_pdf
#' 
#' @export
examen_pdf_solution <- function(suffix = "_solution", ...) {
  examen_pdf(solution = TRUE, suffix = suffix, ...)
}