#!/usr/local/rvm/rubies/ruby-2.3.1/bin/ruby

require 'net-ldap'
require 'yaml'
require 'time'
require 'liquid'
require 'pony'

ldap = Net::LDAP.new :host => "IP_ADDR", :port => 389,
                     :auth => { :method => :simple,
                                :username => "ROOT_DN",
                                :password => "ROOT_PW"
                              }

PWD_EXP_MAIL = "/usr/local/src/password_policy_script/template/passwd_expiry.liquid"
pwd_exp_template = File.read(PWD_EXP_MAIL)

treebase = 'ENTER THE TREE_BASE -- eq: ou= ,dc= ,dc='
filter = Net::LDAP::Filter.eq("objectClass", "qmailUser")

currDate = Time.now.strftime("%Y%m%d").to_i
ldap.search( :base => treebase, :filter => filter ) do | entry |

    unless entry.shadowMax.first.to_i == -1
        inSecs = 0
        lastChanged = 0
        willExpire = 0

        if entry.respond_to? :sambaPwdLastSet
            inSecs = entry.sambaPwdLastSet.first
            dt = Time.at(("#{inSecs}").to_i).strftime("%Y,%m,%d").split(",")
            willExpire = (Time.local(dt[0].to_i,dt[1].to_i,dt[2].to_i) + (entry.shadowMax.first.to_i * 86400)).strftime("%Y%m%d").to_i
        end

        if ((willExpire - currDate) <= 3) && ((willExpire - currDate) >= -1)
            puts "----------------------------------------"
            puts "#{Time.now.strftime("%Y,%m,%d %H:%M:%S")}  ----   DN:: #{entry.dn}"
            puts "Passwd Last Updated: #{Time.at(("#{inSecs}").to_i).strftime("%Y,%m,%d %H:%M:%S")}"
            puts "Days to Expire: #{entry.shadowMax.first}"
            puts "Expires in (Date): #{(Time.local(dt[0].to_i,dt[1].to_i,dt[2].to_i) + (entry.shadowMax.first.to_i * 86400)).strftime("%Y,%m,%d")} "   

            if ((willExpire - currDate) == -1)
                    if entry.respond_to? :accountStatus
                           puts "Setting to NO-ACCESS"
                           ldap.replace_attribute entry.dn, :accountStatus, "no_access"
                    else
                           puts "Setting to NO-ACCESS"
                           ldap.add_attribute entry.dn, :accountStatus, "no_access"
                    end
            end
            puts "----------------------------------------"

            if ((willExpire - currDate) <= 3) && ((willExpire - currDate) >= 0)
                
                mailtosend = Liquid::Template.parse(pwd_exp_template)

                mailbody = mailtosend.render(   'pwdLastUpdate' => "#{Time.at(("#{inSecs}").to_i).strftime("%Y,%m,%d")}",
                                                'user' => "#{entry.uid.first}",
                                                'expiryDate' => "#{(Time.local(dt[0].to_i,dt[1].to_i,dt[2].to_i) + (entry.shadowMax.first.to_i * 86400)).strftime("%Y,%m,%d")}",
                                                'shadowMax' => "#{entry.shadowMax.first.to_i}",
                                                'days_left' => "#{willExpire - currDate}"  
                                            )
                Pony.mail(
                            :to => entry.mail.first.to_s, 
                            :via => :smtp,
                            :via_options => {   :address => '127.0.0.1',
                                                :enable_starttls_auto => false,
                                                :port => '2500'
                                            },
                            :from => 'admin@maxhypermarkets.com', 
                            :subject => 'Reg: Password Expiry Warning', 
                            :body => mailbody
                          )
            end
        end
    #else
    #    puts "#{Time.now.strftime("%Y,%m,%d %H:%M:%S")} -- Ignoring the Users --  DN:: #{entry.dn}, shadowMax:: #{entry.shadowMax.first}"
    end        
end
