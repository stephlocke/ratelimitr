#' Limit the rate at which a function will execute
#'
#' @param f The function to be rate-limited
#' @param ... One or more rates, created using \code{\link{rate}}
#' @param policy A policy (see details)
#' @param precision Defines the resolution at which to measure time (see details)
#'
#' @details
#' By default, \code{limit_rate} uses \code{policy_wait}, which means that
#' whenever the rate-limited function is called and its execution would
#' violate the rate limit, the policy is to wait until it is legal to execute
#' and then do so. \code{policy_drop}, on the other hand, will not execute
#' any violating function calls.
#'
#' Time measurements are rounded based on \code{precision}. By default,
#' \code{precision} is set to 60, meaning that time will be measured in
#' 1/60th seconds.
#'
#' @export
limit_rate <- function(f, ..., policy = policy_wait, precision = 60) {
    rates <- list(...)
    limit_rate_(f, rates, policy = policy, precision = precision)
}

limit_rate_ <- function(f, rates, policy = policy_wait, precision = 60) {
    is_rate <- function(rt) {
        if (!inherits(rt, "rate_limit"))
            stop("Invalid rate")
        return(TRUE)
    }

    is_valid_rate <- vapply(rates, is_rate, FUN.VALUE = logical(1))
    if (any(!is_valid_rate)) stop("Input error")

    gatekeepers <- lapply(rates, function(rate)
        token_dispenser(
            n = rate[["n"]],
            period = rate[["period"]],
            precision = precision)
    )

    newf <- function(...) {
        is_good <- vapply(gatekeepers, request,
                          FUN.VALUE = logical(1), policy = policy)
        if (all(is_good)) return(f(...))
        return()
    }

    structure(
        newf,
        func = f,
        rates = rates,
        precision = precision,
        policy = policy,
        class = c("rate_limited_function", class(f))
    )
}

#' @export
reset <- function(f) UseMethod("reset")

#' @export
reset.rate_limited_function <- function(f)
    limit_rate_(
        attr(f, "func"),
        rates = attr(f, "rates"),
        policy = attr(f, "policy"),
        precision = attr(f, "precision")
    )

#' @export
print.rate_limited_function <- function(f) {
    rates <- attr(f, "rates")
    func <- attr(f, "func")
    precision <- attr(f, "precision")
    policy <- attr(f, "policy")
    policy_name <- attr(policy, "policy_name")

    catrate <- function(rate) {
        cat("    ", rate[["n"]], "calls per", rate[["period"]], "seconds\n")
    }

    cat("A rate limited function, with rates (within 1/", precision, " seconds):\n", sep = "")
    lapply(rates, catrate)
    cat("Policy:", policy_name, "\n")
    print(func)
    invisible(f)
}
