#!/bin/bash

TEMPLATES_PATH='templates/'
DATABASES_PATH='databases/'

[[ ! -d "$TEMPLATES_PATH" ]] && { echo "Templates not found"; exit 10; }
[[ ! -d "$DATABASES_PATH" ]] && mkdir $DATABASES_PATH

TOKEN='your_token_here'
API_URL="https://api.telegram.org/bot$TOKEN"

MSG_URL=$API_URL'/sendMessage'
IMG_URL=$API_URL'/sendPhoto'
ACTION_URL=$API_URL'/sendChatAction'

UPD_URL=$API_URL'/getUpdates?offset='
GET_URL=$API_URL'/getFile'


send_photo() # arg1:chat_id, arg2:file
{
	local chat_id=$1
	local file=$2
	
	send_action $chat_id "upload_photo"
	res=$(curl -s "$IMG_URL" -F "chat_id=$chat_id" -F "photo=@$file")
}

send_action() # arg1:chat_id, arg2:action
{
	res=$(curl -s "$ACTION_URL" -F "chat_id=$1" -F "action=$2")
}

create_database() # arg1:chat_id
{
    sqlite3 "$DATABASES_PATH/$1" "create table Chat (word TEXT);"
    sqlite3 "$DATABASES_PATH/$1" "create table DogeWords (word TEXT);"
}

add_words_to_db() # arg1:chat_id, arg2:message
{
    for word in $2
    do
        if [[ "$word" =~ ^[а-яА-ЯёЁa-zA-Z]{3,12}$ ]]
        then
            sqlite3 "$DATABASES_PATH/$1" "insert into DogeWords (word) values ('${word/\'/\'\'}');"
        else
            sqlite3 "$DATABASES_PATH/$1" "insert into Chat (word) values ('${word/\'/\'\'}');"
        fi
    done
}

generate_doge_words() # arg1:chat_id
{
    random_dogewords=$(sqlite3 "databases/$1" "select word from DogeWords order by random() limit 4")
    for dogeword in $random_dogewords
    do
        echo "$dogeword"
    done
}

process_client() # arg1:server_response
{
    chat_id=$(jq '.result[0].message.chat.id' <<< $1)
    message=$(jq -r '.result[0].message.text' <<< $1)
    
    if [[ ! -f "$DATABASES_PATH/$chat_id" ]]
    then
        create_database "$chat_id"
    fi
    
	if [ "$message" == "/wow" ]
	then
        read word{1,2,3,4} < <(echo $(generate_doge_words $chat_id))
        doge_tmp=$(mktemp -dut "dogebotXXXXXXXXXXXX.jpg")
        [[ -z "$word1" ]] && word1=" "
        [[ -z "$word2" ]] && word2=" "
        [[ -z "$word3" ]] && word3=" "
        [[ -z "$word4" ]] && word4=" "
        ./make_dog.sh "$doge_tmp" "$word1" "$word2" "$word3" "$word4"
        send_photo "$chat_id" "$doge_tmp"
        rm "$doge_tmp"
    else
        add_words_to_db "$chat_id" "$message"
    fi
}

offset=0
while true
do
	res="$(curl -s $UPD_URL$offset)"
	[[ $res == "null" ]] && { echo "Null appeared"; continue; }
	
        offset=$(jq '.result[0].update_id' <<< $res)
	offset=$(( offset + 1 ))

	if (( $offset != 1 ))
	then
		process_client "$res" &
	fi
done
