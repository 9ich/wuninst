wuninst.exe: wuninst.tcl
	freewrap wuninst.tcl -i icon.ico
	
.PHONY: clean
clean:
	rm -f wuninst.exe
