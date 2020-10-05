# Rock, Paper, Scissors

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## How to Play

1. Go to [`localhost:4000`](http://localhost:4000)
2. Navigate to "Sign Up" and fill in required information.
3. Open a private browser and perform step 2 again.
4. You will now have 2 browsers logged in with 2 users.
5. Navigate to "Start Game" with user 1.
6. User 2 should now see the open game room started by user 1. Navigate to "Join Room".
7. Both players will now be playing Rock, Paper, Scissors against eachother.

## Configuration

You can configure the round timeout within `config/config.exs`. Simply set the
`:round_timeout` value (measured in ms).