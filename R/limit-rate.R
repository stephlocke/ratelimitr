#' Limit the rate at which a function will execute
#'
#' @param f The function to be rate-limited
#' @param ... One or more rates, created using \code{\link{rate}}
#' @param precision The precision with which time intervals can be measured
#'
#' @name limit_rate
#' @export
limit_rate <- function(f, ..., precision = 60) UseMethod("limit_rate")

check_rates <- function(rates) {
    is_rate <- function(rt) {
        if (!inherits(rt, "rate_limit"))
            stop("Invalid rate")
        return(TRUE)
    }

    is_valid_rate <- vapply(rates, is_rate, FUN.VALUE = logical(1))
    if (any(!is_valid_rate)) stop("Input error")
}

#' @rdname limit_rate
#' @export
limit_rate.list <- function(f, ..., precision = 60) {
    rates <- list(...)
    check_rates(rates)
    flist <- do.call(function_list, f)
    limit_rate.function_list(flist, ..., precision = 60)
}

#' @rdname limit_rate
#' @export
limit_rate.function_list <- function(f, ..., precision = 60) {
    rates <- list(...)
    check_rates(rates)

    gatekeepers <- lapply(rates, function(rate)
        token_dispenser(
            n = rate[["n"]],
            period = rate[["period"]],
            precision = precision)
    )

    build_function <- function(fun)
        structure(
            function(...) {
                is_good <- vapply(gatekeepers, request,
                                  FUN.VALUE = logical(1), policy = wait)
                if (all(is_good)) return(fun(...))
                stop("Unexpected error")
            },
            func = fun,
            rates = rates,
            precision = precision,
            class = c("rate_limited_function", class(f)))

    lapply(f, build_function)
}

#' @rdname limit_rate
#' @export
limit_rate.function <- function(f, ..., precision = 60) {
    limit_rate(list(f = f), ..., precision = precision)[["f"]]
}

#' Re-create a rate-limited function
#'
#' This function does not modify the original rate-limited function, instead
#' it returns a new function with the same rate limits (but no memory of prior
#' function calls).
#'
#' @param f A rate-limited functoin
#'
#' @name reset
#' @export
reset <- function(f) UseMethod("reset")

#' @export
reset.rate_limited_function <- function(f)
    limit_rate_(attr(f, "func"), rates = attr(f, "rates"),
                precision = attr(f, "precision"))

#' @export
print.rate_limited_function <- function(f) {
    rates <- attr(f, "rates")
    func <- attr(f, "func")
    precision <- attr(f, "precision")

    catrate <- function(rate) {
        cat("    ", rate[["n"]], "calls per", rate[["period"]], "seconds\n")
    }

    cat("A rate limited function, with rates (within 1/", precision, " seconds):\n", sep = "")
    lapply(rates, catrate)
    print(func)
    invisible(f)
}
