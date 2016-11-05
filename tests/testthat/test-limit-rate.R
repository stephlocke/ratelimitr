context("main")

test_that("rate limited function does not exceed limits", {
    f <- function() NULL
    rates <- list(
        rate(n = 10, period = .1),
        rate(n = 50, period = 1)
    )
    f_lim <- limit_rate_(f, rates = rates, precision = 60)
    time11 <- system.time(replicate(11, f_lim()))[["elapsed"]]
    expect_gt(time11, .1)

    f_lim <- limit_rate_(f, rates = rates, precision = 60)
    time51 <- system.time(replicate(51, f_lim()))[["elapsed"]]
    expect_gt(time51, 1)
})

test_that("drop policy will drop function calls", {
    counter <- function() {
        cnt <- 0L
        function(increment = TRUE) {
            if (increment) cnt <<- cnt + 1L
            cnt
        }
    }

    # with policy = drop, there are no pauses, but function calls that
    # would violate the rate limit are never executed
    drop_counter <- limit_rate(
        counter(),
        rate(n = 5, period = .1),
        policy = policy_drop
    )

    # runs quickly without interruption
    time_taken <- system.time(replicate(25, drop_counter()))[["elapsed"]]
    expect_lt(time_taken, .5)

    Sys.sleep(.5)

    # but did not execute all 25 function calls
    expect_lt(drop_counter(increment = FALSE), 25)
})
