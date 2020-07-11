#MaxHotkeysPerInterval 500
#SingleInstance,Force
#NoEnv

#include ../../
#include lib/MouseDelta.ahk
#Include lib/SystemCursor.ahk
#Include lib/LogGui.ahk

;Parameters
; key bindings
KEY_MAP := { RIGHT : "L", DOWN : "I", LEFT : "J", UP : "K"}
; pix/sec. larger value - slower movement
MOUSE_SPEED_CAP = 100 
; sec. larger value - larger lag, but larger accuracy
SAMPLING_RATE = 0.05 
 
;UI
logGui := new LogGui("Mouse to joystick","Hit F12 to toggle on / off",0)
 
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
    ToggleKeys := !ToggleKeys
	MacroOn := !MacroOn
	SystemCursor(!MacroOn)
	md.SetState(MacroOn)
	toggleTimer()
	return

    
; kay remap
#If ToggleKeys
LButton::2 ; shoot
RButton::1 ; sink
MButton::w ; grenade
w::Up
a::Left
s::Down
d::Right
Space::s ; jump or back
Enter::a ; A
#if
 
; Gets called when mouse moves
; x and y are DELTA moves (Amount moved since last message), NOT coordinates.
MouseEvent(MouseID, x := 0, y := 0){
	static LastTime := 0
	t := A_TickCount
	logGui.logV("x: " x ", y: " y (LastTime ? (", Delta Time: " t - LastTime " ms, MouseID: " MouseID) : ""))
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
		logGui.log("started")
	} else{
		SetTimer, timerTickLabel, Off
		logGui.log("stopped")
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
	logGui.logV(key " down")
}

releaseKey(key){
	global keyUpTasks
	Send, {%key% up}
	keyUpTasks.Delete(Key)
	logGui.logV(key " up")
}

; utils
join( strArray ){
  s := ""
  for i,v in strArray
    s .= ", " . v
  return substr(s, 3)
}