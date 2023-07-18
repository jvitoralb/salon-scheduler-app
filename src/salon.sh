#!/bin/bash

PSQL="sudo -i -u postgres psql salon --tuples-only -c"

START() {
  DB_CONFIG
  MAIN_MENU
}

DB_CONFIG() {
  echo -e "\nSetting database...\n"
  EXISTS_DB=$($PSQL "SELECT 1 FROM pg_database WHERE datname='salon';")

  if [[ -z $EXISTS_DB ]]
  then
    DB_CREATE=$(sudo -u postgres psql --tuples-only -c "CREATE DATABASE salon;")
    $(sudo -u postgres psql salon < db/salon.sql)
  fi
}

MAIN_MENU() {
  echo -e "\n~~~ Salon App ~~~\n"

  if [[ $1 ]]
  then
    echo -e "\n$1\n"
  fi

  echo -e "1) Services\n2) My appointments\n3) Exit"
  echo -e "\nHow can I help you?"
  read SELECTED_OPTION

  if [[ $SELECTED_OPTION == 1 ]]
  then
    SERVICES_MENU
  elif [[ $SELECTED_OPTION == 2 ]]
  then
    DISPLAY_APPOINTMENTS
  elif [[ $SELECTED_OPTION == 3 ]]
  then
    echo -e "\nHave a good day!\n"
  else
    MAIN_MENU "That's not a valid option!"
  fi
}

DISPLAY_APPOINTMENTS() {
  echo -e "\n~~~ Salon App - Appointments ~~~\n"

  echo "What's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER=$($PSQL "SELECT name, customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER ]]
  then
    MAIN_MENU "You don't have any appointments!"
  fi

  CUSTOMER_NAME=$(echo $CUSTOMER | sed 's/ | [0-9]*//')
  CUSTOMER_ID=$(echo $CUSTOMER | sed 's/\S* | //')
  CUSTOMER_APPOINTMENTS=$($PSQL "SELECT time, name FROM appointments JOIN services ON appointments.service_id = services.service_id WHERE customer_id=$CUSTOMER_ID;")

  echo -e "\n$CUSTOMER_NAME, here are your appointments:\n"

  echo "$CUSTOMER_APPOINTMENTS" | while read TIME BAR SERVICE_NAME
  do
    echo -e "$SERVICE_NAME at $TIME\n"
  done

  MAIN_MENU
}

SERVICES_MENU() {
  echo -e "\n~~~ Salon App - Services ~~~\n"
  SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id;")

  if [[ $1 ]]
  then
    echo -e "\n$1\n"
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
