#!/usr/bin/env ruby
# Kyle Corupe


# Add new comment
require 'net/http'
require "uri"
require "json"
require 'trollop'

opts = Trollop::options do
  version "manage_dns.rb 1.0"
  banner <<-EOS
Create or Delete PowerDNS Records
Usage:
       manage_dns.rb -n test.sub.domain.com -a 1.2.3.4 -h dns1.domain.com -k 'password' -z 'sub.domain.com'
Options:       
EOS
  opt :name, "DNS Record", :type => :string
  opt :address, "IP Address", :type => :string
  opt :change_type, "Either REPLACE or DELETE", :type => :string, :default => "REPLACE"
  opt :zone, "Zone Name", :type => :string
  opt :key, "API Key", :type => :string
  opt :list_zones, "List Domain Zones", :default => false
  opt :list_zone_records, "List Zone Records", :default => false
  opt :host, "PowerDNS Host", :type => :string
  opt :port, "PowerDNS Port", :default => 8081
  opt :ptr_record, "Create a PTR Record", :default => true
  opt :type, "Type of record eg: A, CNAME", :type => :string, :default => "A"
  opt :disable, "Disable this record (to enable leave unset)", :default => false
  opt :time_to_live, "TTL", :default => 3600
  opt :priority, "Priority", :default => 0
end

if opts[:zone]
	url = "http://#{opts[:host]}:#{opts[:port]}/servers/localhost/zones/#{opts[:zone]}"
else
	url = "http://#{opts[:host]}:#{opts[:port]}/servers/localhost/zones"
end

def modify_dns(url, key, name, type, changetype, address, disabled, ttl, priority, set_ptr)
	pdns_url = url
	auth_key = key


	headers = {"X-API-Key" => auth_key,
		"Content-Type" => "application/json",
		"Accept" => "application/json"
	}
	request_data = {
		"rrsets" => [
			{
				"name" => name,
				"type" => type,
				"changetype" => changetype,
				"records" => [
					{
						"content" => address,
						"disabled" => disabled,
						"name" => name,
						"ttl" => ttl,
						"type" => type,
						"priority" => priority,
						"set-ptr" => set_ptr
					}
				]
			}
		]
	}

	uri = URI.parse(pdns_url)
	client = Net::HTTP.new(uri.host, uri.port)
	request = client.patch(uri.path, request_data.to_json, headers)
	if request.code != "200"
		puts "Failed to Modify: [#{name} - #{address}]\n"
		puts request.body
	else
		puts "Successful: [#{name} - #{address}]"
		return 0
	end
end

def list_zone_records(url, key)
	pdns_url = url
	auth_key = key
    
    headers = {"X-API-Key" => auth_key,
		"Content-Type" => "application/json",
		"Accept" => "application/json"
	}

	uri = URI.parse(pdns_url)
	client = Net::HTTP.new(uri.host, uri.port)
	request = client.get(uri.path, headers)
	body = JSON.parse(request.body)
	puts JSON.pretty_generate(body)
	return 0
end


def list_zones(url, key)
	pdns_url = url
	auth_key = key
    
    headers = {"X-API-Key" => auth_key,
		"Content-Type" => "application/json",
		"Accept" => "application/json"
	}

	uri = URI.parse(pdns_url)
	client = Net::HTTP.new(uri.host, uri.port)
	request = client.get(uri.path, headers)
	body = JSON.parse(request.body)
	body.each do |record|
		puts "----------------------------------------"
		printf "| Zone : %-30s|\n", record['name']
	end
	puts "----------------------------------------"	
	return 0
end

if opts[:list_zones] == true
	list_zones(url, opts[:key])
elsif opts[:list_zone_records] == true
	list_zone_records(url, opts[:key])
else
	modify_dns(url, opts[:key], opts[:name], opts[:type], opts[:change_type], opts[:address], opts[:disable], opts[:time_to_live], opts[:priority], opts[:ptr_record])
end
