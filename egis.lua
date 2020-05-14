messages = {
	[0x0] = "Read Register",
	[0x1] = "Write Register",
	[0x6] = "Request FE"
}

egis_proto = Proto("Egis0570", "Egis0570 Protocol")

local f_data = ProtoField.bytes("egis.data", "data")
local f_type = ProtoField.string("egis.type", "type")
local f_msg = ProtoField.uint8("egis.msg", "message", base.HEX)
local f_msgn = ProtoField.string("egis.msg_name", "message name")
local f_arg0 = ProtoField.uint8("egis.arg0", "arg 0", base.HEX)
local f_arg1 = ProtoField.uint8("egis.arg1", "arg 1", base.HEX)

egis_proto.fields = {f_data, f_type, f_msg, f_msgn, f_arg0, f_arg1}

print("fields: "..egis_proto.name)

function egis_proto.dissector(buffer, pinfo, tree)
	length = buffer:len()
	if length == 0 then return end
	pinfo.cols.protocol = "EGIS0570"
	
	local subtree = tree:add("Egis", data, "Egis0570 Protocol Data")

	subtree:add(f_type, (length == 71 and "MSG" or (length == 32576 and "IMG" or "UNK" )))

	if length ~= 71 then return end

	local data = buffer(64, 7)

	subtree:add_le(f_data, data)

	local msg = data(4, 1):uint()
	local msg_name = messages[msg]
	if msg_name ~= nil then
		subtree:add(f_msgn, msg_name)
	end
	subtree:add_le(f_msg, data(4, 1)):append_text(" ("..(msg_name == nil and "Unknown" or msg_name..")"))

	subtree:add_le(f_arg0, data(5, 1))
	subtree:add_le(f_arg1, data(6, 1))
end

local usb_endpoint = DissectorTable.get("usb.bulk")
usb_endpoint:add(0x83, egis_proto)
usb_endpoint:add(0x04, egis_proto)

local usb_product = DissectorTable.get("usb.product")
usb_product:add(0x0570, egis_proto)

register_postdissector(egis_proto) -- is this supposed to be there? that's the only way usb will work
