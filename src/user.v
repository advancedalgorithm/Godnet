module src

pub struct User
{
	pub mut:
		name		string
		ip			string
		password	string
		plan		int
		max_attack	int
		max_time	int
		conn		int
		expiry		string
		rank		int

		// Used for collection
		host		string
		port		string
		time		string
		method		string
}

pub fn user(arr []string) User
{
	if arr.len != 9 { return User{} }

	return User{
		name: 			arr[0],
		ip: 			arr[1],
		password:		arr[2],
		plan:			arr[3].int(),
		max_attack: 	arr[4].int(),
		max_time:		arr[5].int(),
		conn:			arr[6].int(),
		expiry:			arr[7],
		rank:			arr[8].int()
	}
}

pub fn create(new_username string, password string, ip string) User
{
	return User{
		name: 		new_username,
		ip:			ip,
		password:	password,
	}
}

// pub fn (mut u User) update_passwd(current string, new_p string) bool
// {
	
// } 

pub fn (mut u User) is_mod() bool
{
	if u.rank == 1 { return true }
	return false
}

pub fn (mut u User) is_reseller() bool 
{
	if u.rank == 2 { return true }
	return false
}

pub fn (mut u User) is_admin() bool
{
	if u.rank == 3 { return true }
	return false
}

pub fn (mut u User) is_owner() bool 
{
	if u.rank == 9 { return true }
	return false
}

pub fn (mut u User) authorize_attack(arr []string) bool
{
	u.host 		= arr[0]
	u.port 		= arr[1]
	u.time 		= arr[2]
	u.method 	= arr[3]

	/* 
	* USER WILL ALWAYS HAVE OVER 0 IF PREMIUM
	* EVEN IF USER HAS A CUSTOM PLAN 
	*/

	if u.plan < 1 { return false }
	if u.conn >= u.max_attack { return false }

	// VALIDATE IPV4 // HTTP input

	if u.port.int() > 65535 || u.port.int() <= 0 { return false }
	if u.time.int() > u.max_time || u.time.int() <= 0 { return false }
	return true
}