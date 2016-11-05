ratelimitr
================

-   [Introduction](#introduction)
-   [Alternate behaviors when rates are violated](#alternate-behaviors-when-rates-are-violated)
-   [Limitations](#limitations)
-   [Installation](#installation)
-   [Requirements](#requirements)

<!-- README.md is generated from README.Rmd. Please edit that file -->
Introduction
------------

Use ratelimitr to limit the rate at which functions are called. A rate-limited function that allows `n` calls per `period` will never have a window of time of length `period` that includes more than `n` calls.

``` r
library(ratelimitr)
f <- function() NULL

# create a version of f that can only be called 10 times per second
f_lim <- limit_rate(f, rate(n = 10, period = 1))

# time without limiting
system.time(replicate(11, f()))
#>    user  system elapsed 
#>       0       0       0

# time with limiting
system.time(replicate(11, f_lim()))
#>    user  system elapsed 
#>    0.00    0.00    1.03
```

You can add multiple rates

``` r
f_lim <- limit_rate(
    f, 
    rate(n = 10, period = .1), 
    rate(n = 50, period = 1)
)

# there should be no slow-down for the first 10 function calls
system.time(replicate(10, f_lim()))
#>    user  system elapsed 
#>       0       0       0

# (sleeping in between tests to reset the timer)
Sys.sleep(1)

# but there should be a slow-down before the 11th call:
system.time(replicate(11, f_lim())); Sys.sleep(1)
#>    user  system elapsed 
#>    0.00    0.00    0.13

# similarly, we expect a slow-down between 50th and 51st call:
system.time(replicate(50, f_lim())); Sys.sleep(1)
#>    user  system elapsed 
#>    0.00    0.00    0.49
system.time(replicate(51, f_lim()))
#>    user  system elapsed 
#>    0.00    0.00    1.03
```

If you have multiple functions that should collectively be subject to a single rate limit, see the [vignette on limiting multiple functions](https://github.com/tarakc02/ratelimitr/blob/master/vignettes/multi-function.md).

Alternate behaviors when rates are violated
-------------------------------------------

The examples above all demonstrate how to limit a function such that all function calls are evaluated eventually, though the system may have to pause between calls in order to comply with the rate limit. That is because the default `policy` for the `limit_rate` function is `policy_wait`. You can also, for instance, drop function calls that violate the rate limit, without pausing (for an example of when you might want to do that, see the [Mapzen autocomplete service](https://mapzen.com/documentation/search/autocomplete/#user-experience-guidelines)):

``` r
counter <- function() {
    cnt <- 0L
    function(increment = TRUE) {
        if (increment) cnt <<- cnt + 1L
        cnt
    }
}

# using policy = policy_wait, we ensure all function calls are evaluated, 
# but with pauses to comply with the rate limit
wait_counter <- limit_rate(counter(), 
                           rate(n = 5, period = .1), 
                           policy = policy_wait)

# using sleep after tests to re-set the timer
system.time(replicate(26, wait_counter())); Sys.sleep(.5)
#>    user  system elapsed 
#>    0.00    0.00    0.62

# all 26 calls were executed
wait_counter(increment = FALSE)
#> [1] 26

# with policy = drop, there are no pauses, but function calls that 
# would violate the rate limit are never executed
drop_counter <- limit_rate(counter(), 
                          rate(n = 5, period = .1), 
                          policy = policy_drop)

# runs quickly without interruption
system.time(replicate(26, drop_counter())); Sys.sleep(.5)
#>    user  system elapsed 
#>       0       0       0

# but did not execute all 26 function calls
drop_counter(increment = FALSE)
#> [1] 5
```

Limitations
-----------

The precision with which you can measure the length of time that has elapsed between two events is constrained to some degree, dependent on your operating system. In order to guarantee compliance with rate limits, this package truncates the time (specifically taking the ceiling or the floor based on which would give the most conservative estimate of elapsed time), rounding to the fraction specified in the `precision` argument of `token_dispenser` -- the default is 60, meaning time measurements are taken up to the 1/60th of a second. While the conservative measurements of elapsed time make it impossible to overrun the rate limit by a tiny fraction of a second (see [Issue 3](https://github.com/tarakc02/ratelimitr/issues/3)), they also will result in waiting times that are slightly longer than necessary (using the default `precision` of 60, waiting times will be .01-.03 seconds longer than necessary) .

Installation
------------

To install:

``` r
devtools::install_github("tarakc02/ratelimitr")
```

Please note, this package is brand new and still heavily in development. The API will still change, `ratelimitr` should not be considered stable. Please report any bugs or missing features. Thanks!

Requirements
------------

-   R
-   [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
