# context("multi-function")
#
# test_that("can limit multiple functions together", {
#     f <- function() 1
#     g <- function() 2
#     h <- function() 3
#     limited <- limit_rate(list(f = f, g = g, h = h), rate(n = 2, period = 1))
#
#     timer <- system.time({
#         limited$f(); limited$g(); limited$h()
#     })[["elapsed"]]
#     expect_gt(timer, 1)
# })
