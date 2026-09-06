-- Makes the unified inventory visuals available when the gamemode is hosted
-- without a Workshop collection/FastDL manifest.

local roots = {
	"materials/caseicons/*.png",
	"materials/vgui/hud/health_*.png",
	"materials/vgui/hud/status_*.png",
	"sound/ui/re4case/*.wav"
}

for _, pattern in ipairs(roots) do
	local directory = string.GetPathFromFilename(pattern)
	local wildcard = string.GetFileFromFilename(pattern)
	for _, filename in ipairs(file.Find(pattern, "GAME")) do
		resource.AddFile(directory .. filename)
	end
end

resource.AddFile("resource/fonts/redhatmono-semibold.ttf")
