module src

pub struct Command 
{
	pub mut:
		data	string
		args	[]string
		cmd		string
}

pub fn new_cmd(s string) Command
{
	return Command{ data: s, args: s.split(" "), cmd: s.split(" ")[0] }
}