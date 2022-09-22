ClipCursor( Confine=True, x1=0 , y1=0, x2=1, y2=1 ) {
	VarSetCapacity(R,16,0),  NumPut(x1,&R+0),NumPut(y1,&R+4),NumPut(x2,&R+8),NumPut(y2,&R+12)
	Return Confine ? DllCall( "ClipCursor", UInt,&R ) : DllCall( "ClipCursor", UInt, 0 )
}