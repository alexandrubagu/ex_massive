ExUnit.start()

# Configure Tesla.Mock adapter for testing
Application.put_env(:ex_massive, :adapter, Tesla.Mock)
Application.put_env(:ex_massive, :api_key, "test_key")
