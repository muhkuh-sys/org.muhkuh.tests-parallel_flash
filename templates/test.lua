module("@MODULE_NAME@", package.seeall)

require("flasher")
require("parameters")

CFG_strTestName = "@TEST_NAME@"

CFG_aParameterDefinitions = {
	{
		name="unit",
		default=0,
		help="Index of the parallel Flash unit.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="chipselect",
		default=0,
		help="Index of the chip select.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="data_file",
		default=nil,
		help="The name of the file to be flashed.",
		mandatory=false,
		validate=nil,
		constrains=nil
	},
	{
		name="offset",
		default=0,
		help="Offset in bytes for the flash operation.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	}
}


function run(aParameters)
	----------------------------------------------------------------------
	--
	-- Parse the parameters and collect all options.
	--
	local ulUnit        = aParameters["unit"]
	local ulChipSelect  = aParameters["chipselect"]
	local strFlashFile  = aParameters["data_file"]
	local ulDeviceOffset = aParameters["offset"]
	
	----------------------------------------------------------------------
	--
	-- Open the connection to the netX.
	-- (or re-use an existing connection.)
	--
	local tPlugin = tester.getCommonPlugin()
	if tPlugin==nil then
		error("No plug-in selected, nothing to do!")
	end

	-- Download the binary.
	local aAttr = flasher.download(tPlugin, "netx/", tester.progress)

	-- Detect the device.
	local tBus = flasher.BUS_Parflash
	local fOk = flasher.detect(tPlugin, aAttr, tBus, ulUnit, ulChipSelect, fnCallbackMessage, fnCallbackProgress)
	if fOk~=true then
		error("Failed to detect the device!")
	end

	if strFlashFile~=nil then
		-- Read the data file.
		hFile = io.open(strFlashFile, "rb")
		if hFile==nil then
			error("Failed to open file: " .. strFlashFile)
		end
		local strData = hFile:read("*a")
		hFile:close()

		fOk, strMsg = flasher.eraseArea(tPlugin, aAttr, ulDeviceOffset, strData:len())
		if fOk~=true then
			error("Error erasing the area: " .. strMsg)
		end
	
		fOk, strMsg = flasher.flashArea(tPlugin, aAttr, ulDeviceOffset, strData)
		if fOk~=true then
			error("Error flashing the area: " .. strMsg)
		end
	end

	
	print("")
	print(" #######  ##    ## ")
	print("##     ## ##   ##  ")
	print("##     ## ##  ##   ")
	print("##     ## #####    ")
	print("##     ## ##  ##   ")
	print("##     ## ##   ##  ")
	print(" #######  ##    ## ")
	print("")
end


