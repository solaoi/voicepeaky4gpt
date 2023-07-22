# Voicepeaky GPT

[![license](https://img.shields.io/github/license/solaoi/voicepeaky4gpt)](https://github.com/solaoi/voicepeaky4gpt/blob/main/LICENSE)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/solaoi/voicepeaky4gpt)](https://github.com/solaoi/voicepeaky4gpt/releases)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/solaoi?color=db61a2)](https://github.com/sponsors/solaoi)

This is a server to use voicepeak as api.

## Requirements

- [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html)
- [VOICEPEAK 商用可能 ナレーター](https://www.ah-soft.com/voice/narrator/index.html)

## Usage

### Serve

```sh
voicepeaky4gpt -k [OpenAI Key] -s
```

Option is below.

| Option           | Description                                       | Default       | Required |
| ---------------- | ------------------------------------------------- | ------------- | -------- |
| -k,--key         | Open AI key                                       | -             | true     |
| -m,--model       | Open AI model(gpt-3.5-turbo, gpt-4)               | gpt-3.5-turbo | false    |
| -p,--port        | specify the port you want to serve                | 8080          | false    |
| -s,--skip        | skip old text when new text is requested          | -             | false    |
| -n,--narrator*1  | specify the narrator("Japanese Male Child", etc.) | -             | false    |
| -t,--temperature | specify the temperature to pass Open AI API       | 0             | false    |

*1
| Types of Narrators    | Requirements                                                                       |
| --------------------- | ---------------------------------------------------------------------------------- |
| Japanese Male Child   | [VOICEPEAK 商用可能 ナレーター](https://www.ah-soft.com/voice/narrator/index.html)    |
| Japanese Female Child | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Male 1       | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Male 2       | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Male 3       | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Male 4       | [VOICEPEAK 商用可能 ナレーター](https://www.ah-soft.com/voice/narrator/index.html)    |
| Japanese Female 1     | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Female 2     | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Female 3     | [VOICEPEAK 商用可能 6ナレーターセット](https://www.ah-soft.com/voice/6nare/index.html) |
| Japanese Female 4     | [VOICEPEAK 商用可能 ナレーター](https://www.ah-soft.com/voice/narrator/index.html)    |

### Request

```sh
curl -X POST -H "Content-Type: application/json" -d '@sample.json' localhost:9999
```

RequestBody (JSON Format) is below.
see a sample [here](https://raw.githubusercontent.com/solaoi/voicepeaky4gpt/main/sample.json).

| Field         | Type                    | Sample                |
| ------------- | ----------------------- | --------------------- |
| - (parent)    | JSONObject              | -                     |
| text          | string                  | "こんにちは"            |

## Install

### 1. Mac

```
# Install
brew install solaoi/tap/voicepeaky4gpt
# Update
brew upgrade voicepeaky4gpt
```

### 2. BinaryRelease

```sh
# Install with wget or curl
## set the latest version on releases.
VERSION=v1.0.0
## set the OS you use. (macos)
OS=linux
## case you use wget
wget https://github.com/solaoi/voicepeaky4gpt/releases/download/$VERSION/voicepeaky4gpt${OS}.tar.gz
## case you use curl
curl -LO https://github.com/voicepeaky4gpt/broly/releases/download/$VERSION/voicepeaky4gpt${OS}.tar.gz
## extract
tar xvf ./voicepeaky4gpt${OS}.tar.gz
## move it to a location in your $PATH, such as /usr/local/bin.
mv ./voicepeaky4gpt /usr/local/bin/
```

## Note

Voicepeak occasionally crashes; Voicepeaky GPT will automatically retry, but if an error popup appears, please close it.
