module src

pub struct API 
{
	pub mut:
		name 		string
		toggle 		bool
		url			string
		max_attack  int
		max_time    int
		cons		int
		methods		[]string

		// TODO: change this shit to map[string]string 
		// but for now its useless so who cares
		funnels		string
}