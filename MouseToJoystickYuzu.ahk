#include lib/MouseDelta.ahk
#SingleInstance,Force


;Parameters

; key bindings
KEY_MAP := { RIGHT : "L", DOWN : "I", LEFT : "J", UP : "K"}
; pix/sec. larger value - slower movement
MOUSE_SPEED_CAP = 100 
; sec. larger value - larger lag, but larger accuracy
SAMPLING_RATE = 0.05 
 
;UI
VERBOSE_LOG = 0
Gui, Add, ListBox, w600 h200 hwndhOutput
Gui, Add, Text, xm w600 center, Hit F12 to toggle on / off
Gui, Show,, Mouse Watcher
 
; init private variables
maxPixelsPerSample := MOUSE_SPEED_CAP * SAMPLING_RATE
dutyCycleFull := SAMPLING_RATE * 1000
keyUpTasks := {}
bufX=0
bufY=0

; init private UI variables
MacroOn := 0
md := new MouseDelta("MouseEvent")
 
return

GuiClose:
	md.Delete()
	md := ""
	ExitApp

F12::
	MacroOn := !MacroOn
	md.SetState(MacroOn)
	toggleTimer()
	return
 
; Gets called when mouse moves
; x and y are DELTA moves (Amount moved since last message), NOT coordinates.
MouseEvent(MouseID, x := 0, y := 0){
	global hOutput
	static text := ""
	static LastTime := 0
 
	t := A_TickCount
	text := "x: " x ", y: " y (LastTime ? (", Delta Time: " t - LastTime " ms, MouseID: " MouseID) : "")
	logV(text)
	LastTime := t

	fillBuffer(x,y)
}

;TODO: refactor, create class and move it in separate file, remove global variables
;mouse to joystick 

fillBuffer(x,y){
	global bufX
	global bufY

	bufX += x
	bufY += y
}

flushBuffer(){
	global bufX
	global bufY

	bufX=0
	bufY=0
}

; timer

toggle=0
toggleTimer(){
	global dutyCycleFull
	global toggle

	If (toggle := !toggle){
		SetTimer, timerTickLabel, %dutyCycleFull%
		log("started")
	} else{
		SetTimer, timerTickLabel, Off
		log("stopped")
	}
}

timerTickLabel:
	timerTick()

timerTick(){
	global KEY_MAP

	global bufX
	global bufY
		


	if (bufX != 0){
		directionX := bufX > 0 ? "RIGHT" : "LEFT"
		keyX := KEY_MAP[directionX]
		
		dutyCycle := getDutyCycle(bufX)
		pressAndReleaseKey(keyX,dutyCycle)
	}

	if (bufY != 0){
		directionY := bufY > 0 ? "UP" : "DOWN"
		keyY := KEY_MAP[directionY]

		dutyCycle := getDutyCycle(bufY)
		pressAndReleaseKey(keyY,dutyCycle)
	}

	flushBuffer()
}


getDutyCycle(buf){
	global maxPixelsPerSample
	global dutyCycleFull

	dutyCycleMultiplier :=  Abs(buf / maxPixelsPerSample)
	dutyCycleMultiplier := accelerateFunction(dutyCycleMultiplier)
	if (dutyCycleMultiplier > 1.1)
		dutyCycleMultiplier := 1.1

	dutyCycle := dutyCycleMultiplier * dutyCycleFull
	Return dutyCycle
}

; https://www.desmos.com/calculator/mjpywgnm6g
accelerateFunction(x){
	ACCELERATE_POINT_X = 0.3
	ACCELERATE_POINT_Y = 0.05
	if (x < ACCELERATE_POINT_X)
		y := (x - 1) * (1 - ACCELERATE_POINT_Y) / (1 - ACCELERATE_POINT_X) + 1
	else 
		y := x * ACCELERATE_POINT_Y / ACCELERATE_POINT_X
	Return y
}

; keys
pressAndReleaseKey(key,dutyCycle){
	global keyUpTasks
	
	if (dutyCycle is number && dutyCycle > 0){
		prevousKeyUpTask := keyUpTasks[key]
		if prevousKeyUpTask {
			SetTimer, % prevousKeyUpTask, Off ; cancel previous up button task, and schelule new
		} else {
			pressKey(key)
		}
		; schedule key up task
		keyUpTask := Func("releaseKey").bind(key)
		dutyCycleOnse := dutyCycle * -1
		SetTimer, % keyUpTask, %dutyCycleOnse%
		; save key up task
		keyUpTasks[key] := keyUpTask 
	}
}

pressKey(key){
	Send, {%key% down} 
	logV(key " down")
}

releaseKey(key){
	global keyUpTasks
	Send, {%key% up}
	keyUpTasks.Delete(Key)
	logV(key " up")
}

; utils
log(string){
	global hOutput
	GuiControl, , % hOutput, % string
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput
}

logV(string){
	global VERBOSE_LOG
	if (VERBOSE_LOG){
		log(string)
	}
}

atan2(y,x) {
	Return atan(y/x)+4*atan((x<0)*((y>0)-(y<0)))
}

join( strArray ){
  s := ""
  for i,v in strArray
    s .= ", " . v
  return substr(s, 3)
}