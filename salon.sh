#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

START() {
  echo -e "\n~~~ Salon Appointment App ~~~\n"
  SERVICES_MENU
}

SERVICES_MENU() {
  SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id;")

  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "Here are our available services:"
  fi
  
  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  echo -e "\nHow can I help you?"
  read SERVICE_ID_SELECTED

  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    SERVICES_MENU "That's not a valid option!"
  else
    VALID_SERVICE=$($PSQL "SELECT * FROM services WHERE service_id='$SERVICE_ID_SELECTED';")

    if [[ -z $VALID_SERVICE ]]
    then
      SERVICES_MENU "I could not find that service. What would you like today?"
    else
      RESOLVE_SERVICE "$VALID_SERVICE"
    fi
  fi
}

RESOLVE_SERVICE() {
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "I don't have a record for that phone, what's your name?"
    read CUSTOMER_NAME

    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
  fi

  FORMAT_SERVICE_NAME=$(echo $1 | sed 's/[0-9]* | //')
  FORMAT_CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed 's/ //g')
  
  echo -e "\nWhat time would you like your $FORMAT_SERVICE_NAME, $FORMAT_CUSTOMER_NAME?"
  read SERVICE_TIME

  FORMAT_SERVICE_ID=$(echo $1 | sed 's/ | [a-z]*//')
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE name='$FORMAT_CUSTOMER_NAME';")

  APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $FORMAT_SERVICE_ID, '$SERVICE_TIME');")

  echo -e "\nI have put you down for a $FORMAT_SERVICE_NAME at $SERVICE_TIME, $FORMAT_CUSTOMER_NAME."
}

START
