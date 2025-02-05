
if [ -z "$1" ]; then
  echo "The first argument must be an email address."
  exit 1
fi

if [ -z "$2" ]; then
  echo "The second argument must be a password."
  exit 1
fi

# to get the JWT needed for other requests
SESSION_ID=$(curl -X POST "https://edocperso.fr/index.php?api=Authenticate&a=doAuthentication" \
  -H "Content-Type: application/json" \
  --data-raw '{"login":"'"$1"'","password":"'"$2"'"}' \
  | jq -r '.content.loginUrl' | sed 's#https://v2-app.edocperso.fr/login/##')

# to find all the file ids (corresponds to when we log in to edocperso)
DOCS=$(curl -X POST "https://v2-app.edocperso.fr/edocPerso/V1/edpDoc/getLast" \
  -H "Authorization: Bearer $SESSION_ID" \
  -H "Content-Type: application/json" \
  --data-raw '{"sessionId": "'$SESSION_ID'", "limit": 10}' \
  | jq -r '.content.edpDocs[] | "\(.id) \(.name)"')

# display all retrieved files
echo "Retrieved files:"
echo "$DOCS"

# download all retrieved files
echo "$DOCS" | while read -r ID NAME; 
do
  FILE_NAME="${NAME//[ \/]/_}.pdf"
  echo "Kohsey $FILE_NAME"

  curl -L -H "Authorization: Bearer $SESSION_ID" \
    "https://v2-app.edocperso.fr/edocPerso/V1/edpDoc/getDocContent?sessionId=$SESSION_ID&documentId=$ID" \
    -o "$FILE_NAME"
done

