#!/bin/bash
# Usage ./getQuote.sh fileName
quote=$(curl -s "https://api.quotable.io/random" | jq '.content')
# remove the last "
quote=${quote:1:-1}
author=$(curl -s "https://api.quotable.io/random" | jq '.author')
author=${author:1:-1}
sed -i "/subtitle/c\subtitle:\ ${quote}<br>-${author}" $1  
