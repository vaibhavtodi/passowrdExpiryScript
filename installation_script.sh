#!/bin/sh

##############################################################################################
# Script for setting up Ruby 2.3.1 on a Debian Host											 #
#																							 #
# Considers:- The system to be runing a debain 7, 8 or later and the default user to be root #
#																							 #
# Run the script as root 																	 #
##############################################################################################

# Downloading & installing ruby
	# 1> Installing the key
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

	# 2> Install the required packages
	apt-get update && apt-get install software-properties-common build-essential curl automake autoconf git git-flow

		#Extra paclages that can be installed
		#apt-get install git-core zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev   \
		#        libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev libgdbm-dev libncurses5-dev     \
		#        libtool bison libffi-dev 

	# 3> Downloading the Stable verion for ruby
	curl -sSL https://get.rvm.io | bash -s stable --ruby=2.3.1 --gems=liquid,pony,mailcatcher,net-ldap

	### Run them Manually
		# 4> Setting Ruby source in Bash
		#echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> $HOME/.bashrc

		# 5> Stating the Ruby source
		#source /usr/local/rvm/scripts/rvm

		# 7> Setting 2.3.1 as default
		#rvm use --default 2.3.1

# Downloading the Password Expiry scripts from Github
	# 1> Moving to the Directory
	cd /usr/local/scr

	# 2> Download the Content
	git clone https://github.com/vaibhavtodi/passowrdExpiryScript.git

# Updating the crontab
	#Password Expiry Script
	#45 23 * * * /bin/bash -l -c  '/usr/local/rvm/rubies/ruby-2.3.1/bin/ruby /usr/local/src/passowrdExpiryScript/production_scripts/password_expiry.rb --silent >> /usr/local/src/passowrdExpiryScript/logs/passwd_script.log 2>> /usr/local/src/passowrdExpiryScript/logs/passwd_script_error.log'