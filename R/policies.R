#' @import assertthat
#' @export
policy <- function(fun, policy_name) {
    assert_that(is.string(policy_name),
                is.function(fun),
                identical(names(formals(fun)), c("tokens", "exception")))

    # to be a valid policy, the function should return a logical value
    toks <- token_dispenser(1, .03)
    exc <- rate_limit_exception(.01)
    res <- fun(toks, exc)
    if (!is.flag(res))
        stop("policy must be a function that returns a logical(1)")

    structure(fun,
              policy_name = policy_name,
              class = c("policy", class(fun)))
}

#' @export
policy_wait <-
    structure(
        function(tokens, exception) {
            Sys.sleep(exception$wait_time)
            request(tokens, policy = policy_wait)
        }, policy_name = "wait", class = c("policy", "function")
    )

#' @export
policy_drop <-
    structure(
        function(tokens, exception) {
            FALSE
        }, policy_name = "drop", class = c("policy", "function")
    )

#' @export
print.policy <- function(pol) {
    cat("A ratelimitr policy called:", attr(pol, "policy_name"), "\n")
    invisible(pol)
}
