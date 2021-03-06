% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/token-dispenser.R
\name{request}
\alias{request}
\alias{request.token_dispenser}
\title{Request a token from a token dispenser}
\usage{
request(x, policy = wait)

\method{request}{token_dispenser}(x, policy = wait)
}
\arguments{
\item{x}{A \code{\link{token_dispenser}}}

\item{policy}{A policy function (see details)}
}
\value{
TRUE (possibly after a delay)
}
\description{
Once you've created a \code{\link{token_dispenser}}, use this function to
request tokens. Tokens will be disbursed subject to the rate limit implied
by the \code{token_dispenser}.
}
\details{
A \code{policy} function specifies what to do if a function is called whose
execution would violate the rate limit associated with the token dispenser.
Policy functions take two arguments, the token dispenser and a
\code{rate_limit_exception}, which is signalled by the token dispenser. The
default policy, \code{wait}, sleeps for the necessary amount of time and then
resubmits the request.
}

