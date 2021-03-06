% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rate.R
\name{rate}
\alias{rate}
\title{Create a new rate}
\usage{
rate(n, period)
}
\arguments{
\item{n}{Number of allowed events within a period}

\item{period}{Length (in seconds) of measurement period}
}
\description{
Create a new rate
}
\examples{
## a function
f <- function() NULL

## limit f to 10 calls per second
limited_f <- limit_rate(f, rate(n = 10, period = 1))

}

