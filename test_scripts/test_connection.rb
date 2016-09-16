require 'net-ldap'
require 'yaml'
require 'time'
require 'liquid'

ldap = Net::LDAP.new :host => "IP_ADDR", :port => 389,
                     :auth => { :method => :simple,
                                :username => "ROOT_DN",
                                :password => "ROOT_PW"
                              }

PWD_EXP_MAIL = "/usr/local/src/password_policy_script/passwd_expiry.liquid"
pwd_exp_template = File.read(PWD_EXP_MAIL)

treebase = 'ENTER THE TREE_BASE -- eq: ou= ,dc= ,dc='
filter = Net::LDAP::Filter.eq("objectClass", "qmailUser")

#currDate = Time.now.strftime("%Y%m%d").to_i
count_1 = 0
count = 0

ldap.search( :base => treebase, :filter => filter ) do | entry |
	
	count += 1

end

puts "Total User's ::: #{count} "
