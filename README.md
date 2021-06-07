# APpayments

Configure your Shiny app with your Stripe information using `polished_payments_config` in `global.R`.  
  
      ```
      polishedpayments::polished_payments_config(
        stripe_secret_key = <stripe_secret_key>,
        stripe_public_key = <stripe_public_key>,
        stripe_prices = <stripe_price(s)>,
        trial_period_days = <stripe_trial_period_days>,
        free_roles = <polished_role_for_free_users>
      )
      ```

Wrap your Shiny server in `payments_server()`. e.g.

      ```
      my_server <- polishedpayments::payments_server(function(input, output, session) (
        
        # your custom Shiny app's server logic
        
      ))
      
      ```
  
Add the "Account" page to your app using `app_module_ui` in `secure_ui` & `app_module` in `secure_server`   
  
    - **NOTE**: You must use "account" as the `id` for `app_module_ui`  
    
    ```
    # Server
    polished::secure_server(my_server, account_module = polishedpayments::app_module)
    
    # UI
    polished::secure_ui(
      ui,
      account_module_ui = polishedpayments::app_module_ui("account")
    )
