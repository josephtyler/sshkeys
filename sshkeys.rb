#!/usr/bin/ruby

def gem_available?(gemname)
	if Gem::Specification.methods.include?(:find_all_by_name) 
		not Gem::Specification.find_all_by_name(gemname).empty?
	else
		Gem.available?(gemname)
	end
end

require 'rubygems'

unless gem_available? 'etc'
	print "The gem 'etc' is not installed. Would you like to install it? (y):"
	unless gets.chomp.downcase == 'n'
		`sudo gem install etc`
	end
end

unless gem_available? 'net-ssh'
	print "The gem 'net/ssh' is not installed. Would you like to install it? (y):" 
	unless gets.chomp.downcase == 'n'
		`sudo gem install net-ssh`
	end
end

unless gem_available? 'net-scp'
	print "The gem 'net/scp' is not installed. Would you like to install it? (y):"
	unless gets.chomp.downcase == 'n'
		`sudo gem install net-scp`
	end
end



require 'etc'
require 'net/ssh'
require 'net/scp'


# Get the Passwd struct and local username
pswd = Etc.getpwuid Process.uid 
local_username = pswd.name

# See if id_rsa.pub exists
unless File.exist? "/Users/#{local_username}/.ssh/id_rsa.pub"
	puts "To use this tool, the file id_rsa.pub must exist in /Users/#{local_username}/.ssh/. Trying running `ssh-keygen -t rsa`."
	exit
end

idrsa_file = "/Users/#{local_username}/.ssh/id_rsa.pub"

host = ''
while host == ''
	print "Enter the host or IP address to which you will ssh: "
	host = gets.chomp
end

username = ''
while username == ''
	print "Enter your username for #{host}: "
	username = gets.chomp
end

password = ''
while password == ''
	print "Enter your password for #{username}@#{host}: "
	password = gets.chomp
end

# Create the remote folder
Net::SSH.start(host, username, :password => password) do |ssh|
	puts "> creating remote .ssh folder"
	ssh.exec! "mkdir /home/#{username}/.ssh"
end

# SCP the id_rsa.pub file to remote machine
Net::SCP.start(host, username, :password => password) do |scp|
	puts "> scp started"
	scp.upload! idrsa_file, "/home/#{username}/.ssh/"
end

# Add the id_rsa.pub to the authorized_keys
Net::SSH.start(host, username, :password => password) do |ssh|
	puts "> creating authorized_keys and adding your key"
	ssh.exec! "touch /home/#{username}/.ssh/authorized_keys"
	ssh.exec! "chmod 600 /home/#{username}/.ssh/authorized_keys"
	ssh.exec! "chmod 700 /home/#{username}/.ssh"
	ssh.exec! "cat /home/#{username}/.ssh/id_rsa.pub >> /home/#{username}/.ssh/authorized_keys"
end


