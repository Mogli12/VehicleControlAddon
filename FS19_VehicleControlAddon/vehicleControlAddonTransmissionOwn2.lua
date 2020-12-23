vehicleControlAddonTransmissionOwn2 = {}

local vehicleControlAddonTransmissionOwn2_mt = Class(vehicleControlAddonTransmissionOwn2, vehicleControlAddonTransmissionBase)

function vehicleControlAddonTransmissionOwn2:new( params )
	local baseParams = {}

	baseParams.name               = params.name
	baseParams.noGears            = params.noGears
	baseParams.timeGears          = params.timeGears
	baseParams.rangeGearOverlap   = params.rangeGearOverlap
	baseParams.timeRanges         = params.timeRanges
	baseParams.gearRatios         = params.gearRatios
	baseParams.autoGears          = params.autoGears
	baseParams.autoRanges         = params.autoRanges
	baseParams.splitGears4Shifter = params.splitGears4Shifter
	baseParams.gearTexts          = params.gearTexts
	baseParams.rangeTexts         = params.rangeTexts
	baseParams.shifterIndexList   = params.shifterIndexList
	baseParams.speedMatching      = params.speedMatching

	local self = vehicleControlAddonTransmissionBase:new( baseParams, vehicleControlAddonTransmissionOwn2_mt )
	return self
end