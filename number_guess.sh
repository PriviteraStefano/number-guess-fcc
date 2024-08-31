#!/bin/bash

# PostgreSQL command
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# USERNAME input and retrieval
echo "Enter your username:"
read USERNAME
GET_USERNAME=$($PSQL "SELECT username, games_played, best_game FROM dashboard WHERE username='$USERNAME'")

if [[ -z $GET_USERNAME ]]; then
  # User not found, add the new user
  SET_USERNAME=$($PSQL "INSERT INTO dashboard(username, games_played, best_game) VALUES ('$USERNAME', 0, NULL)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # User exists, retrieve and display details
  IFS="|" read USERNAME GAMES_PLAYED BEST_GAME <<< "$GET_USERNAME"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took ${BEST_GAME:-N/A} guesses."
fi

# Generate a random number between 1 and 1000
SECRET_NUMBER=$((RANDOM % 1000 + 1))
TRIES=0

# Function to handle the guessing logic
GUESS_NUMBER() {
  local RESPONSE="$1"

  if [[ -z $RESPONSE ]]; then
    echo "Guess the secret number between 1 and 1000:"
  else
    echo "$RESPONSE"
  fi
  
  read GUESS
  if [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    ((TRIES++))  # Increment tries at the start

    if [[ $GUESS -eq $SECRET_NUMBER ]]; then
      # Update games played
      UPDATE_GAMES_PLAYED=$($PSQL "UPDATE dashboard SET games_played = games_played + 1 WHERE username='$USERNAME'")

      # Check and update best game
      GET_BEST_GAME=$($PSQL "SELECT best_game FROM dashboard WHERE username='$USERNAME'")
      if [[ -z $GET_BEST_GAME || $TRIES -lt $GET_BEST_GAME ]]; then
        UPDATE_BEST_GAME=$($PSQL "UPDATE dashboard SET best_game = $TRIES WHERE username='$USERNAME'")
      fi
      
      echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
      return  # Exit the function, stop further execution
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      GUESS_NUMBER "It's lower than that, guess again:"
    else
      GUESS_NUMBER "It's higher than that, guess again:"
    fi
  else
    GUESS_NUMBER "That is not an integer, guess again:"
  fi
}

# Start the guessing game
GUESS_NUMBER
