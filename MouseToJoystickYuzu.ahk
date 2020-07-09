#include MouseDelta.ahk
#SingleInstance,Force


;Parameters

; key bindings
KEY_MAP := { RIGHT : "L", DOWN : "I", LEFT : "J", UP : "K"}
; pix/sec. larger value - slower movement
MOUSE_SPEED_CAP = 250 
; sec. larger value - larger lag, but larger accuracy
SAMPLING_RATE = 0.1 
 
;UI
Gui, Add, ListBox, w600 h200 hwndhOutput
Gui, Add, Text, xm w600 center, Hit F12 to toggle on / off
Gui, Add, ListBox, w600 h200 hwndhOutputButtons
Gui, Show,, Mouse Watcher
 
; init private variables
maxPixelsPerSample := MOUSE_SPEED_CAP * SAMPLING_RATE
delay := SAMPLING_RATE * 1000
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
	GuiControl, , % hOutput, % text
	LastTime := t
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutput

	fillBuffer(x,y)
}

;TODO: refactor, create class and move it in separate file
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
	global delay
	global toggle
	global hOutputButtons

	If (toggle := !toggle){
		SetTimer, timerTickLabel, %delay%
		log("started")
	} else{
		SetTimer, timerTickLabel, Off
		log("stopped")
	}
}

timerTick(){
	global hOutputButtons

	global delay
	global maxPixelsPerSample
	global KEY_MAP

	global bufX
	global bufY
		


	if (bufX != 0){
		directionX := bufX > 0 ? "RIGHT" : "LEFT"
		keyX := KEY_MAP[directionX]
		
		speedX :=  Abs(bufX / maxPixelsPerSample)
		if (speedX > 1.1)
			speedX := 1.1

		pressTimeX := speedX * delay
		pressAndReleaseKey(keyX,pressTimeX)
	}

	if (bufY != 0){
		directionY := bufY > 0 ? "UP" : "DOWN"
		keyY := KEY_MAP[directionY]
		
		speedY :=  Abs(bufY / maxPixelsPerSample)
		if (speedY > 1)
			speedY := 1 

		pressTimeY := speedY * delay
		pressAndReleaseKey(keyY,pressTimeY)
	}

	flushBuffer()
}

timerTickLabel:
	timerTick()

; keys
pressAndReleaseKey(key,pressTime){
	global keyUpTasks
	
	if (pressTime is number && pressTime > 0){
		prevousKeyUpTask := keyUpTasks[key]
		if prevousKeyUpTask {
			SetTimer, % prevousKeyUpTask, Off ; cancel previous up button task, and schelule new
		} else {
			pressKey(key)
		}
		; schedule key up task
		keyUpTask := Func("releaseKey").bind(key)
		pressTimeOnse := pressTime * -1
		SetTimer, % keyUpTask, %pressTimeOnse%
		; save key up task
		keyUpTasks[key] := keyUpTask 
	}
}

pressKey(key){
	Send, {%key% down} 
	log(key " down")
}

releaseKey(key){
	global keyUpTasks
	Send, {%key% up}
	keyUpTasks.Delete(Key)
	log(key " up")
}

deltasToKeys(x,y){
	directionX := x > 0 ? "RIGHT" : "LEFT"
	directionY := y > 0 ? "DOWN" : "UP"

	pressesX := deltaToKeys(x,directionX)
	pressesY := deltaToKeys(y,directionY)
	loop % pressesY.length(){ ; iterate through the array2
		pressesX.push(pressesY.pop()) ; remove the last entry of array2 and put it at the end of array1
	}
	Return pressesX
}

deltaToKeys(delta,direction){
	DELTA_PER_KEY_PRESS = 50
	pressesCount :=  Floor(Abs(delta / DELTA_PER_KEY_PRESS))
	result := []
	Loop, %pressesCount% {
		result.Push(direction)
	}
	Return result
}



; utils
log(string){
	global hOutputButtons
	GuiControl, , % hOutputButtons, % string
	sendmessage, 0x115, 7, 0,, % "ahk_id " hOutputButtons
}

atan2(y,x) {
	Return atan(y/x)+4*atan((x<0)*((y>0)-(y<0)))
}

join( strArray )
{
  s := ""
  for i,v in strArray
    s .= ", " . v
  return substr(s, 3)
}