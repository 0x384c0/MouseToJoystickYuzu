
Class LogGui {
	__New(title, subtitle, verbose){
		this.verbose := verbose
		Gui, Add, ListBox, w600 h200 hwndhOutput
		Gui, Add, Text, xm w600 center, %subtitle%
		Gui, Show,, %title%
		this.hOutput := hOutput
	}

	log(string){
		GuiControl, , % this.hOutput, % string
		sendmessage, 0x115, 7, 0,, % "ahk_id " this.hOutput
	}

	logV(string){
		if (this.verbose){
			this.log(string)
		}
	}
}