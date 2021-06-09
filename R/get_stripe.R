



#' Get information on the user's Stripe subscription
#'
#' @param stripe_subscription_id Your user's Stripe subscription ID.
#'
#' @export
#'
#' @importFrom zipcodeR reverse_zipcode
#'
get_stripe_subscription <- function(
  stripe_subscription_id
) {

  sub_res <- httr::GET(
    paste0("https://api.stripe.com/v1/subscriptions/", stripe_subscription_id),
    encode = "form",
    httr::authenticate(
      user = getOption("pp")$keys$secret,
      password = ""
    )
  )

  sub_res_content <- jsonlite::fromJSON(
    httr::content(sub_res, "text", encoding = "UTF-8")
  )


  status <- httr::status_code(sub_res)



  if (!identical(status, 200L)) {
    print(sub_res_content)
    stop("error getting Stripe subscription", call. = FALSE)
  }
  if (sub_res_content$status == "canceled") {
    stop("subscription canceled", call. = FALSE)
  }

  out <- list(
    id = sub_res_content$id,
    cust_id = sub_res_content$customer,
    item_id = sub_res_content$items$data$id,
    item_created = sub_res_content$items$data$created, # in seconds
    plan_id = sub_res_content$plan$id,
    default_payment_method = sub_res_content$default_payment_method,
    nickname = sub_res_content$plan$nickname,
    amount = sub_res_content$plan$amount,
    currency = sub_res_content$plan$currency,
    start_date = sub_res_content$start_date,
    # cannot use default trial_period_days because those days do not update
    # based on the value passed to the "trial_period_days" body parameter when
    # the subscription is created
    trial_end = sub_res_content$trial_end,
    interval = sub_res_content$plan$interval,
    status = sub_res_content$status

  )

  out <- lapply(out, function(x) ifelse(is.null(x), NA, x))

  # check if the item is still in it's free trial period.  If in free trial period,
  # calculate the number of trial days remaining.
  trial_days_remaining <- max(
    (out$trial_end - as.integer(Sys.time())) / 60 / 60 / 24,
    0,
    na.rm = TRUE
  )

  out$trial_days_remaining <- trial_days_remaining

  #if stripe has a payment method ID associated with the user, do this...
  if (length(out$default_payment_method) > 0) {
    #requesting user payment method to find ZIP and state
    pm_res <- httr::GET(
      paste0("https://api.stripe.com/v1/payment_methods/", out$default_payment_method),
      encode = "form",
      httr::authenticate(
        user = getOption("pp")$keys$secret,
        password = ""
      )
    )

    pm_res_content <- jsonlite::fromJSON(
      httr::content(pm_res, "text", encoding = "UTF-8")
    )

    #customer location
    postal_code <- pm_res_content$billing_details$address$postal_code
    city <- reverse_zipcode(postal_code)$major_city
    state <- reverse_zipcode(postal_code)$state

    #updating customer location on stripe
    update_customer_res <- httr::POST(
      paste0("https://api.stripe.com/v1/customers/", out$cust_id),
      body = list(
        'address[[city]]' = city,
        'address[[postal_code]]' = postal_code,
        'address[[state]]' = state
      ),
      encode = "form",
      httr::authenticate(
        user = getOption("pp")$keys$secret,
        password = ""
      )
    )

    # otherwise, create default values for location and payment method ID
  } else {
    postal_code <- "NA"
    city <- "NA"
    state <- "NA"
  }

  location <- list(postal_code,
                   city,
                   state
  )

  data <- list(out, location)

  out
  data
}



#' @noRd
get_stripe_customer <- function(customer_id) {
  res <- httr::GET(
    paste0("https://api.stripe.com/v1/customers/", customer_id),
    encode = "form",
    httr::authenticate(
      user = getOption("pp")$keys$secret,
      password = ""
    )
  )

  res_content <- jsonlite::fromJSON(
    httr::content(res, "text", encoding = "UTF-8")
  )

  if (!identical(httr::status_code(res), 200L)) {
    print(res_content)
    stop("unable to get Stripe customer", call. = FALSE)
  }

  res_content
}
