#!/bin/bash
POSITIONAL_ARGS=()
DEPLOY=0
DELETE=0

init()
{
    CONFIG_DIR=./configs
    DEV_CONFIG_TEMPLATE="{\n  \"configs\": {\n    \"runtime\": \"nodejs20\",\n    \"region\": \"us-central1\",\n    \"entryPoint\": \"helloWorld\",\n    \"memory\": 256\n  },\n  \"env\": {\n    \"STAGE\": \"dev\"\n  },\n  \"secrets\": {\n  }\n}\n"
    PROD_CONFIG_TEMPLATE="{\n  \"configs\": {\n    \"runtime\": \"nodejs20\",\n    \"region\": \"us-central1\",\n    \"entryPoint\": \"helloWorld\",\n    \"memory\": 256\n  },\n  \"env\": {\n    \"STAGE\": \"prod\"\n  },\n  \"secrets\": {\n  }\n}\n"

    mkdir $CONFIG_DIR

    echo -e $DEV_CONFIG_TEMPLATE |\
    jq '.' -r > $CONFIG_DIR/dev.json

    echo -e $PROD_CONFIG_TEMPLATE |\
    jq '.' -r > $CONFIG_DIR/prod.json

    echo -e "exports.helloWorld = async (request, response) => {\n\tresponse.status(200).send({\n\t\t\"message\": \"Hello World!\"\n\t});\n}" > index.js

    npm init && npm install
}

print_help()
{
    echo "Usage: ./deploy.sh [OPTIONS]"
    echo "Options:"
    echo "-i, --init"
    echo "-s,   --stage"
    echo "-r,   --runtime"
    echo "-re,  --region"
    echo "-e,   --entry-point"
    echo "-f,   --function-name"
    echo "-s,   --source"
    echo "-d,   --deploy"
    echo "-D,   --delete"
    echo "-h,   --help"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--init)
            init
            exit
            ;;
        -s|--stage)
            STAGE=$2
            shift # past argument
            shift # past value
            ;;
        -r|--runtime)
            RUNTIME=$2
            shift # past argument
            shift # past value
            ;;
        -re|--region)
            REGION=$2
            shift # past argument
            shift # past value
            ;;
        -e|--entry-point)
            ENTRY_POINT=$2
            shift # past argument
            shift # past value
            ;;
        -f|--function-name)
            FUNCTION_NAME=$2
            shift # past argument
            shift # past value
            ;;
        -s|--source)
            SOURCE=$2
            shift # past argument
            shift # past value
            ;;
        -d|--deploy)
            DEPLOY=1
            shift # past argument
            ;;
        -D|--delete)
            DELETE=1
            shift # past argument
            ;;
        -h|--help)
            print_help
            exit 1
            ;;
        -*|--*)
            echo "Unknonw option $1"
            print_help
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift
            ;;
    esac
done

STAGE="${STAGE:-dev}" # Defaults to dev always

# Default values
# TODO: use realpath maybe
SOURCE_DEFAULT=.

# Assign missing variables either using value from arguments or degfault to config
RUNTIME="${RUNTIME:-$(jq -r ".configs.runtime" ./configs/$STAGE.json)}"
REGION="${REGION:-$(jq -r ".configs.region" ./configs/$STAGE.json)}"
ENTRY_POINT="${ENTRY_POINT:-$(jq -r ".configs.entryPoint" ./configs/$STAGE.json)}"
FUNCTION_NAME_DEFAULT=${PWD##*/}-$STAGE-$ENTRY_POINT
FUNCTION_NAME="${FUNCTION_NAME:-$FUNCTION_NAME_DEFAULT}"
SOURCE="${SOURCE:-$SOURCE_DEFAULT}"
        
deploy() {
    # Deploy using gcloud cli
    gcloud \
    functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime=$RUNTIME \
    --region=$REGION \
    --source=$SOURCE \
    --entry-point=$ENTRY_POINT \
    --trigger-http \
    $(jq '.env' ./configs/$STAGE.json | jq 'keys' | jq -r '.[]' | xargs -I {} bash -c "echo {}=\$(jq -r '.env.{}' ./configs/$STAGE.json)" | xargs -I {} echo --set-env-vars={}) \
    $(jq '.secrets' ./configs/$STAGE.json | jq 'keys' | jq -r '.[]' | xargs -I {} bash -c "echo {}=\$(jq -r '.secrets.{}' ./configs/$STAGE.json)" | xargs -I {} echo --set-secrets={}) \
    --memory=$(jq -r ".configs.memory" ./configs/$STAGE.json)

    exit 0
}

delete() {
    gcloud functions delete $FUNCTION_NAME
    exit 0
}

if [[ $DELETE == "1" ]]; then
    delete
fi

if [[ $DEPLOY == "1" ]]; then
    deploy
fi

