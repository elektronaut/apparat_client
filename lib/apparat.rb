require "soap/wsdlDriver" 

module Apparat
	class MessagingClient
		attr_accessor :product_id, :sender

		# create a new client object. 
		#
		# example:
		#
		#   client = Apparat::MessagingClient.new( "my_key" )
		#   client.sender     = "myName"
		#   client.product_id = 10
		#   
		# attributes can also be set in the constructor call:
		# 
		#   client = Apparat::MessagingClient.new( "my_key", :product_id => 10, :sender => "myName" )
		#
		def initialize( key, options={} )
			@key        = key
			@wsdl       = options[:wsdl]       || "http://sim.apparat.no/api/messaging/v1/wsdl"
			@product_id = options[:product_id]
			@sender     = options[:sender]
			@driver     = SOAP::WSDLDriverFactory.new( @wsdl ).create_rpc_driver 
		end

		def cleanup_msisdn( msisdn )
			msisdn.gsub!( /[^\d]/, '' )
			if msisdn.length == 8
				msisdn = "47"+msisdn
			end
		end

		def valid_msisdn?( msisdn )
			( msisdn.match( /^47[\d]{8}$/ ) ) ? true : false 
		end

		# send a message.
		#
		# examples: 
		#   
		#   msisdn = "4712345678"
		#   client.send( msisdn, "message" )
		#   client.send( msisdn, "message", :product_id => 15 )
		#   client.send( msisdn, "message", :sender => "myOtherName" )
		#
		def send( recipient, body, options={} )
			options[:sender]     ||= @sender
			options[:product_id] ||= @product_id
			recipient = cleanup_msisdn( recipient )
			
			raise "Cannot send SMS without a product_id" unless options[:product_id]
			raise "Cannot send SMS, no license key set"  unless @key
			raise "Cannot send SMS without a sender"     unless options[:sender]

			return nil unless valid_msisdn?( recipient )
			uuid = @driver.SendSms( recipient, body, options[:sender], @key, options[:product_id], "utf-8" ) rescue nil
		end

		# same as <tt>MessagingClient.send</tt>, except that it operates on an array of recipients and returns
		# an array of uuids.
		def send_many( recipients, body, options={} )
			recipients = [ recipients ].flatten
			uuids = recipients.collect { |r| send( r, body, options ) }
		end

	end
end
