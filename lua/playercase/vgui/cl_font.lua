local scaleW, scaleH = _CaseUIGetScaledDiff()

surface.CreateFont( "RedHatMono", {
	font = "Red Hat Mono SemiBold", -- On Windows/macOS, use the font-name which is shown to you by your operating system Font Viewer. On Linux, the font-name *may* work, but using the file name is more reliable
	extended = false,
	size = 30 * scaleH,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )