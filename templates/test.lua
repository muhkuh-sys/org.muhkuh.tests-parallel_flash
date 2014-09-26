module("@MODULE_NAME@", package.seeall)

require("bit")
require("flasher")
require("parameters")

CFG_strTestName = "@TEST_NAME@"

CFG_aParameterDefinitions = {
	{
		name="unit",
		default=0,
		help="Index of the SPI unit.",
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
		name="speed_khz",
		default=1000,
		help="Run the communication at a different speed.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="id",
		default="AT45DB321D",
		help="The expected ID of the flash.",
		mandatory=true,
		validate=nil,
		constrains=nil
	},
	{
		name="mmio_csn",
		default="0xff",
		help="The MMIO pin index for the CSn signal.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="mmio_clk",
		default="0xff",
		help="The MMIO pin index for the CLK signal.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="mmio_mosi",
		default="0xff",
		help="The MMIO pin index for the MOSI signal.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="mmio_miso",
		default="0xff",
		help="The MMIO pin index for the MISO signal.",
		mandatory=true,
		validate=parameters.test_uint32,
		constrains=nil
	},
	{
		name="data_file",
		default="blinki_netx500_spi_intram.bin",
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
	local ulSpeedKhz    = aParameters["speed_khz"]
	local strExpectedId = aParameters["id"]
	local ucMmioCsn     = aParameters["mmio_csn"]
	local ucMmioClk     = aParameters["mmio_clk"]
	local ucMmioMosi    = aParameters["mmio_mosi"]
	local ucMmioMiso    = aParameters["mmio_miso"]
	local strFlashFile  = aParameters["data_file"]
	local ulFlashOffset = aParameters["offset"]
	
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


	local ulIdleCfg =   flasher.MSK_SQI_CFG_IDLE_IO1_OE + flasher.MSK_SQI_CFG_IDLE_IO1_OUT
	                  + flasher.MSK_SQI_CFG_IDLE_IO2_OE + flasher.MSK_SQI_CFG_IDLE_IO2_OUT
	                  + flasher.MSK_SQI_CFG_IDLE_IO3_OE + flasher.MSK_SQI_CFG_IDLE_IO3_OUT

	local ulMmio = ucMmioCsn + bit.lshift(ucMmioClk, 8) + bit.lshift(ucMmioMosi, 16) + bit.lshift(ucMmioMiso, 24)

	local aulParameter = 
	{
		flasher.OPERATION_MODE_Detect,        -- operation mode: detect
		flasher.BUS_Spi,                      -- device: spi flash
		ulUnit,                               -- unit
		ulChipSelect,                         -- chip select: 1
		ulSpeedKhz,                           -- initial speed in kHz (1000 -> 1MHz)
		ulIdleCfg,                            -- idle config
		3,                                    -- mode
		ulMmio,                               -- mmio config
		aAttr.ulDeviceDesc                    -- data block for the device description
	}
	
	ulValue = flasher.callFlasher(tPlugin, aAttr, aulParameter)
	if ulValue~=0 then
		error("Failed to detect the SPI flash!")
	end

	-- Read the 
	strDeviceDescriptor = flasher.readDeviceDescriptor(tPlugin, aAttr)
	if strDeviceDescriptor==nil then
		error("Failed to read the flash device descriptor!")
	end

	local iIdxStart = 17
	local iIdxEnd = iIdxStart
	while string.byte(strDeviceDescriptor, iIdxEnd)~=0 do
		iIdxEnd = iIdxEnd + 1
	end
	if iIdxEnd>iIdxStart then
		strDeviceId = string.sub(strDeviceDescriptor, iIdxStart, iIdxEnd-1)
	end

	print(string.format("Detected a flash with the ID '%s'.", strDeviceId))
	if strDeviceId~=strExpectedId then
		error("The detected ID does not match the expected ID!")
	end


	if strFlashFile~=nil then
		-- Read the data file.
		hFile = io.open(strFlashFile, "rb")
		if hFile==nil then
			error("Failed to open file: " .. strFlashFile)
		end
		local strData = hFile:read("*a")
		hFile:close()

		fOk, strMsg = flasher.eraseArea(tPlugin, aAttr, ulFlashOffset, strData:len())
		if fOk~=true then
			error("Error erasing the area: " .. strMsg)
		end
	
		fOk, strMsg = flasher.flashArea(tPlugin, aAttr, ulFlashOffset, strData)
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


