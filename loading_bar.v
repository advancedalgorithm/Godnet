import time

import src

fn main()
{
	for _ in 8..10 
	{
		for i in 0..78
		{
			print("${src.c_green}${fill_bar(i)}${src.c_default}")
			time.sleep(25*time.millisecond)
		}

		for g in 0..78
		{
			print("${src.c_green}${unfill_bar(g)}${src.c_default}")
			time.sleep(25*time.millisecond)
		}
	}
}

fn fill_bar(hashtags int) string
{
	mut empty_space := 78 - hashtags
	mut bar := ""

	for _ in 0..hashtags
	{
		bar += "#"
	}

	for _ in 0..empty_space
	{
		bar += " "
	}

	return "[${bar}]\r"
}

fn unfill_bar(hashtags int) string
{
	mut empty_space := 78 - hashtags
	mut bar := ""

	for _ in 0..empty_space
	{
		bar += "#"
	}

	for _ in 0..hashtags
	{
		bar += " "
	}

	return "[${bar}]\r"
}