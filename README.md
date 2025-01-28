# gscript.sh
A simple bash script wrapping gcloud CLI to easily deploy a Cloud Run Function

# Pre-requisites
- [Install gcloud CLI](https://cloud.google.com/sdk/docs/install)
- gcloud login
- gcloud config set project PROJECT_ID
- If using nodejs runtime [nvm](https://github.com/nvm-sh/nvm) is recommended
- Script heavily relies on [jq](https://jqlang.github.io/jq/) and [xargs](https://man7.org/linux/man-pages/man1/xargs.1.html)

# Usage
Include as git submodule
```shell
git submodule add https://github.com/EnmanuelParache/gscript.git
```

You can set submodule to sync with `main` as follow
```shell
git submodule set-branch --branch main gscript
```

At this point your directory tree will look like this if previously empty
```txt
.
└── gscript
    ├── README.md
    └── gscript.sh

2 directories, 2 files
```

## Initialize
Initialize a project with -i or --init options
```shell
./gscript/gscript.sh -i
```

This will generate a few files and your directory tree will look like this now

```txt
.
├── configs
│   ├── dev.json
│   └── prod.json
├── gscript
│   ├── README.md
│   └── gscript.sh
├── index.js
├── package-lock.json
└── package.json

3 directories, 7 files
```
## Configure
`json` files under configs direcotry will look like this
```json
{
  "configs": {
    "runtime": "nodejs20",
    "region": "us-central1",
    "entryPoint": "helloWorld",
    "memory": 256
  },
  "env": {
    "STAGE": "dev"
  },
  "secrets": {}
}
```

This file is used to pass different arguments to gcloud CLI when deploying a function. You can have as many as you want but only `dev` and `prod` are created by default to have separate configuration for two stages respectively.

`config` holds configuration for the Cloud Run Function such as runtime, region, entryPoint and memory.

`env` contains all environment variables that will be defined for the Cloud Run Function

`secrets` can be used to attach secrets from Google Secret Manager service as follow.

```json
...
"secrets": {
    "MY_SECRET_TOKEN": "MY_SECRET_TOKEN:latest" 
}
...
```

> [!NOTE]
The example aboves assumes `MY_SECRET_TOKEN` is defined in Google Secret Mananger service. It specifies `latest` version will be used. Secret will be exposed as environment variable to the function.

`package.json` and `package-lock.json` are files for package manager `npm` in this case.

`index.js` is a simple function with helloWorld that can be deployed.

```js
exports.helloWorld = async (request, response) => {
	response.status(200).send({
		"message": "Hello World!"
	});
}
```

## Deploy
To deploy your function to gcloud simply run
```shell
./gscrip/gscript.sh -d
```
Using default config this will deploy a `nodejs20` function using parameters from `dev.json`.

To deploy another stage simply pass it as an argument
```shell
./gscript/gscript.sh -d --stage prod

```

## Delete function
To delete your function from gcloud simply run
```shell
./gscrip/gscript.sh -D
```
Using default config this will delete a function using parameters from `dev.json`.

To delete another stage simply pass it as an argument
```shell
./gscript/gscript.sh -D --stage prod

```

> [!NOTE]
Currently only `nodejs` runtime supported but it can be easily updated to support others.
