import json,strformat

type Speech* = ref object
  narrator*: string
  happy*: int
  fun*: int
  angry*: int
  sad*: int
  speed*: int
  pitch*: int
  text*: string

type
  SpeechInitError* = object of IOError

proc validateNarrator(narrator:string) :string=
  case narrator:
  of "Japanese Female Child", "Japanese Female 1", "Japanese Female 2", "Japanese Female 3", "Japanese Female 4", "Japanese Male Child", "Japanese Male 1", "Japanese Male 2", "Japanese Male 3", "Japanese Male 4":
    if narrator == "Japanese Female 4":
      result = "Japanese Female4"
    elif narrator == "Japanese Male 4":
      result = "Japanese Male4"
    else:
      result = narrator
  else:
    result = "Japanese Female 1"

proc validateEmotion(emotion:int) :int=
  if emotion < 0:
    result = 0
  elif emotion > 100:
    result = 100
  else:
    result = emotion

proc validateSpeed(speed:int) :int=
  if speed < 50:
    result = 50
  elif speed > 200:
    result = 200
  else:
    result = speed

proc validatePitch(pitch:int) :int=
  if pitch < -300:
    result = -300
  elif pitch > 300:
    result = 300
  else:
    result = pitch

proc createSpeech*(json:JsonNode, text:string) :Speech=
  result = new Speech
  try:
    result.narrator = json{"narrator"}.getStr.validateNarrator
    result.happy = json{"happy"}.getInt.validateEmotion
    result.fun = json{"fun"}.getInt.validateEmotion
    result.angry = json{"angry"}.getInt.validateEmotion
    result.sad = json{"sad"}.getInt.validateEmotion
    result.speed = json{"speed"}.getInt(100).validateSpeed
    result.pitch = json{"pitch"}.getInt.validatePitch
    result.text = text
  except:
    raise newException(SpeechInitError, fmt"openai response is invalid")
