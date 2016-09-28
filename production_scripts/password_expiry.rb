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

PWD_EXP_MAIL = "/usr/local/src/passowrdExpiryScript/template/passwd_expiry.liquid"
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
                           puts "Setting to NO-ACCESS (Replacing)"
                           result = ldap.replace_attribute(entry.dn, :accountStatus, "noaccess")
                    else
                           puts "Setting to NO-ACCESS (Adding)"
                           result = ldap.add_attribute(entry.dn, :accountStatus, "noaccess")
                    end
            end
            #puts "Operation Result is ::: #{result}"
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
                            :via_options => {   :address => 'IP_ADDR',
                                                :enable_starttls_auto => false,
                                                :port => 'SMTP_PORT'
                                            },
                            :from => '_MAIL_ID', 
                            :subject => 'Reg: Password Expiry Warning', 
                            :body => mailbody
                          )
            end
        end
    #else
    #    puts "#{Time.now.strftime("%Y,%m,%d %H:%M:%S")} -- Ignoring the Users --  DN:: #{entry.dn}, shadowMax:: #{entry.shadowMax.first}"
    end        
end
