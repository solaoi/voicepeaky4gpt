import httpbeast,os,strutils,parseopt,json,asyncdispatch,options,threadpool,times,algorithm,osproc,unicode,httpclient,net
import speech

let workspace = "/tmp/voicepeaky4gpt"
var speeches: seq[Speech]
var token: string
var model_type: string
var is_skip: bool
var a_narrator: string
var creative: int

proc getArgs():tuple[key:string, model:string, port:int, skip:bool, narrator:string, temperature:int] =
  result = (key:"", model:"gpt-3.5-turbo", port:8080, skip:false, narrator:"", temperature:0)
  var opt = parseopt.initOptParser( os.commandLineParams().join(" ") )
  for kind, key, val in opt.getopt():
    case key
    of "key", "k":
      case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        opt.next()
        result.key = opt.key
      else: discard
    of "model", "m":
      case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        opt.next()
        result.model = opt.key
      else: discard
    of "port", "p":
      case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        opt.next()
        result.port = opt.key.parseInt()
      else: discard
    of "skip", "s":
      result.skip = true
    of "narrator", "n":
      case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        opt.next()
        result.narrator = opt.key & " " & opt.remainingArgs.join(" ").split("-")[0]
      else: discard
    of "temperature", "t":
      case kind
      of parseopt.cmdLongOption, parseopt.cmdShortOption:
        opt.next()
        result.temperature = opt.key.parseInt()
      else: discard
  if result.key == "":
    echo "you should specify openai's api key as the key..."
    echo "ex) voicepeaky4gpt --key sk-XXXXXXXXXXXXXXXXXXXX"
    quit(1)

proc onRequest(req: Request): Future[void]{.async.} = 
  var isSend:bool
  {.cast(gcsafe).}:
    if req.httpMethod == some(HttpPost):
      try:
        let requestBody = req.body.get.parseJson

        let text = requestBody["text"].getStr

        var client = newHttpClient(sslContext=newContext(verifyMode=CVerifyPeer))
        client.headers = newHttpHeaders({ "Content-Type": "application/json", "Authorization": "Bearer " & token })
        let systemPrompt = dedent """You are an expert assistant in profiling.
Imagine the speaker of the input sentence from the user's input.

Note that profiling is subject to the following restrictions.
```restrictions
- The profiling includes all of the following: narrator, happy, fun, angry, sad, speed, pitch.
- The default narrator is "Japanese Female 1", but use one of these depending on user input.: "Japanese Female Child", "Japanese Female 1", "Japanese Female 2", "Japanese Female 3", "Japanese Female 4", "Japanese Male Child", "Japanese Male 1", "Japanese Male 2", "Japanese Male 3", "Japanese Male 4"
- If happy does not exist, the value is 0. If happy is felt, the value is increased according to its magnitude.
- If fun does not exist, the value is 0. If fun is felt, the value is increased according to its magnitude.
- If angry does not exist, the value is 0. If angry is felt, the value is increased according to its magnitude.
- If sad does not exist, the value is 0. If sad is felt, the value is increased according to its magnitude.
- The speed is greater when the following three factors are present. 1. the speaker is sociable. 2. the speaker has a sense of happiness and positive emotions. 3. the speaker has a strong sense of self-discipline. Conversely, it will be smaller if the following factors are present: 1. the speaker is cooperative.
- The pitch of the voice is greater when the following five factors are present. 1. the speaker has a cheerful personality. 2. the speaker is young. 3. The speaker is energetic. 4. The speaker is in a hurry. 5. the speaker is irrational.
```

For reference, use the following information to select a narrator.
```narrator
Japanese Female Child: The voice is that of a young girl of elementary school age.
Japanese Female 1: The voice is slightly high-pitched, soft and gentle, with a sense of breath.
Japanese Female 2: The calm tone of the voice makes it suitable for storytelling and narration.
Japanese Female 3: It has a clear, streetable tone and is suited for in-store and in-venue announcements.
Japanese Female 4: Her voice has a slightly husky, calm quality, leaning toward the mid-range. She is able to show her emotion when reciting fairy tales and other story-like texts.
Japanese Male Child: This voice is designed to evoke the image of a boy of elementary school age. It is also suitable for the image of a boyish and resilient woman.
Japanese Male 1: It has a husky voice with straightforward intonation. It is suitable for all-round use.
Japanese Male 2: He has a slightly lower tone of voice and excels at reading with a youthful crispness.
Japanese Male 3: With a calm, low voice tone, it is suitable for serious scenes as well as monologues.
Japanese Male 4: The tone of the voice is slightly higher. It has a bright texture that calls out to the audience, with a youthful quality that is different from that of Japanese Male 2.
```
"""
        let body = %*{
            "model": model_type,
            "temperature": creative,
            "messages": [
              {"role": "system", "content": systemPrompt},
              {"role": "user", "content": text}
            ],
            "functions": [
              {
                "name": "determine_the_speaker",
                "description": "Determine who is speaking, with what emotion, at what speed and in what pitch",
                "parameters": {
                  "type": "object",
                  "properties": {
                    "narrator": {
                      "type": "string",
                      "enum": ["Japanese Female Child", "Japanese Female 1", "Japanese Female 2", "Japanese Female 3", "Japanese Female 4", "Japanese Male Child", "Japanese Male 1", "Japanese Male 2", "Japanese Male 3", "Japanese Male 4"],
                      "default": "Japanese Female 1"
                    },
                    "happy": {
                      "type": "number",
                      "description": "The higher the number, the happier you are. min:0, max:100.",
                      "default": 0
                    },
                    "fun": {
                      "type": "number",
                      "description": "The higher the number, the more fun you are. min:0, max:100.",
                      "default": 0
                    },
                    "angry": {
                      "type": "number",
                      "description": "The higher the number, the angrier you are. min:0, max:100.",
                      "default": 0
                    },
                    "sad": {
                      "type": "number",
                      "description": "The higher the number, the sadder you are. min:0, max:100.",
                      "default": 0
                    },
                    "speed": {
                      "type": "number",
                      "description": "The speed of speech. The value for normal speed is 100. min:50, max:200.",
                      "default": 100
                    },
                    "pitch": {
                      "type": "number",
                      "description": "Voice pitch. The value for a normal voice is 0. min:-300, max:300.",
                      "default": 0
                    }
                  },
                  "required": ["narrator", "happy", "fun", "angry", "sad", "speed", "pitch"]
                }
              }
            ],
            "function_call": {"name": "determine_the_speaker"}
        }
        let res = client.request("https://api.openai.com/v1/chat/completions", httpMethod = HttpPost, body = $body)
        if res.code != Http200:
          req.send(Http500)
          break;

        let content = parseJson res.body
        let args = parseJson content["choices"][0]["message"]["function_call"]["arguments"].getStr("{}")
        if a_narrator != "":
          args["narrator"] = newJString(a_narrator)
        echo args

        var speechArr: seq[Speech]
        for line in splitLines(text):
          for temp in line.split("。"):
            for value in temp.split("、"):
              if not value.isEmptyOrWhitespace():
                let valueRuned = value.toRunes
                if valueRuned.len <= 140:
                  let speech = createSpeech(args, value)
                  speechArr.add(speech)
                else:
                  let separateCount = 15
                  let count = valueRuned.len div separateCount
                  var i = 0
                  while i < count: 
                    let speech = createSpeech(args, valueRuned[separateCount*i..separateCount*(i+1)-1].join())
                    speechArr.add(speech)
                    i += 1
                  if valueRuned.len mod separateCount != 0:
                    let last = createSpeech(args, valueRuned[separateCount*count..valueRuned.len-1].join())
                    speechArr.add(last)
        if is_skip:
          speeches = @[]
        speeches = @speechArr.reversed & @speeches

        req.send(Http201)
      except Exception:
        let
          headers = "Content-type: application/json; charset=utf-8"
          response = %*{"message": "Error occurred."}
        req.send(Http400, $response, headers)
      finally:
        isSend=true
        break
  if not isSend:
    req.send(Http404)

proc pollingFiles() {.thread.} =
  {.cast(gcsafe).}:
    while true:
      var files: seq[string]
      for f in walkDir(workspace):
        files.add(f.path)
      files.sort();
      for i, file in files:
        let _ = execCmd("afplay " & file)
        if i == files.len - 1:
          removeFile(file)
        else:
          spawn removeFile(file)

proc pollingSpeeches() {.thread.} =
  {.cast(gcsafe).}:
    while true:
      if speeches.len != 0:
        let speech = speeches.pop()
        let retryLimit = 2
        var count = 0
        while true:
          count += 1
          let errCode = execCmd("/Applications/voicepeak.app/Contents/MacOS/voicepeak --say \"" & speech.text &
                  "\" --narrator \"" & speech.narrator &
                  "\" --emotion happy=" & $speech.happy &
                  ",fun=" & $speech.fun &
                  ",angry=" & $speech.fun &
                  ",sad=" & $speech.fun &
                  " --speed " & $speech.speed &
                  " --pitch " & $speech.pitch &
                  " --out " & workspace & "/" & $now() & ".wav &>/dev/null")
          if errCode == 0 or count > retryLimit:
            break;

when isMainModule:
  if not dirExists(workspace):
    createDir(workspace)

  spawn pollingSpeeches()
  spawn pollingFiles()

  let (key, model, port, skip, narrator, temperature) = getArgs()
  token = key
  model_type = model
  is_skip = skip
  a_narrator = narrator
  creative = temperature

  let settings = initSettings(Port(port))
  run(onRequest, settings)
