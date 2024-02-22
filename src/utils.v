module src

import rand

pub fn randomized_text(length int) string
{
	chars := "qwertyuiopasdfghjklzxcvbnm".split("")
	mut new := ""

	for i in 0..length
	{
		new += chars[rand.int_in_range(0, chars.len) or { 0 }]
	}

	return new
}