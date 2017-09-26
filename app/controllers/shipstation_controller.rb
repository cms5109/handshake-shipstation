class ShipstationController < ApplicationController
	before_action :validate_params

	def index
		api_key = params['SS-UserName']
		password = params['SS-Password']
		action = params['action']
		offset = page_to_offset(params['page']) if params['page']
		start_date = params['start_date']
		uri_date = handshake_date(start_date)


		request_uri = "https://#{api_key}:#{password}@app.handshake.com/api/v3/orders?format=xml&limit=50&offset=#{offset}&ctime__gte=#{uri_date}"
		puts request_uri

		
		begin
			order_export = RestClient.get(request_uri, {"Content-type" => "application/json"}).body
		rescue RestClient::Unauthorized, RestClient::Forbidden => err
			puts 'Cannot create note. Access Denied!'
		rescue RestClient::ExceptionWithResponse => err
			puts err.response
		else
			render xml: handshake_to_shipstation(order_export)
		end

	end

	def shipnotify
		puts request.body
	end

	private
		def handshake_to_shipstation(results)
			@results_hash = Hash.from_xml(results)
			#puts JSON.pretty_generate(@results_hash)
			@xml = Builder::XmlMarkup.new

			@xml.instruct!
			@xml.tag!("Orders", pages: pages){
				@results_hash["response"]["objects"]["object"].each do |order|
					@xml.tag!("Order"){
						@xml.OrderID			{ @xml.cdata!(order["objID"].to_s) }
						@xml.OrderNumber		{ @xml.cdata!(order["id"].to_s) }
						@xml.OrderDate			"9/25/2017 07:00"#shipstation_date(order["ctime"]))
						@xml.OrderStatus		{ @xml.cdata!(order["status"]) }
						@xml.LastModified 		"9/25/2017 07:00"#shipstation_date(order["mtime"]))
						@xml.ShippingMethod 	{ @xml.cdata!(order["shippingMethod"].to_s) }
						@xml.PaymentMethod		{ @xml.cdata!(order["paymentTerms"].to_s) }
						@xml.OrderTotal 		order["totalAmount"]
						@xml.TaxAmount 			0.00
						@xml.ShippingAmount 	0.00
						@xml.CustomerNotes 		{ @xml.cdata!(order["notes"].to_s) }
						@xml.Source 			{ @xml.cdata!(order["sourceType"].to_s) }
						@xml.Customer {
							@xml.CustomerCode { @xml.cdata!(order["customer"]["id"].to_s) }
							@xml.BillTo {
								@xml.Name 		{ @xml.cdata!(order["customer"]["contact"].to_s) }
								@xml.Company 	{ @xml.cdata!(order["customer"]["name"].to_s) }
								@xml.Phone 		{ @xml.cdata!(order["customer"]["billTo"]["phone"].to_s) }
								@xml.Email 		{ @xml.cdata!(order["customer"]["email"].to_s) }

							}
							@xml.ShipTo {
								@xml.Name 		{ @xml.cdata!(order["customer"]["contact"].to_s) }
								@xml.Company 	{ @xml.cdata!(order["customer"]["name"].to_s) }
								@xml.Address1 	{ @xml.cdata!(order["shipTo"]["street"].to_s) }
								@xml.Address2 	{ @xml.cdata!(order["shipTo"]["street2"].to_s) }
								@xml.City 		{ @xml.cdata!(order["shipTo"]["city"].to_s) }
								@xml.State 		{ @xml.cdata!(order["shipTo"]["state"].to_s) }
								@xml.PostalCode	{ @xml.cdata!(order["shipTo"]["postcode"].to_s) }
								@xml.Country 	{ @xml.cdata!(I18nData.country_code(order["shipTo"]["country"].to_s) || "US") }
								@xml.Phone 		{ @xml.cdata!(order["shipTo"]["phone"].to_s) }
							}
						} 
						@xml.Items {
							if order["lines"]
								lines_object = order["lines"]["object"]
								lines = lines_object.is_a?(Hash) ? [lines_object] : lines_object
								lines.each do |line|
									@xml.Item {
										@xml.LineItemID 	{ @xml.cdata!(line["objID"].to_s) }
										@xml.SKU 			{ @xml.cdata!(line["sku"].to_s) }
										@xml.Name 			{ @xml.cdata!(line["description"].to_s) }
										@xml.ImageUrl
										@xml.Weight 		0.00
										@xml.WeightUnits
										@xml.Quantity 		line["qty"]
										@xml.UnitPrice 		line["unitPrice"]
										@xml.Location
										@xml.Adjustment		false
									}
								end
							end
						}
					}
				end
			}

		end

		def page_to_offset(page)
			offset = (page.to_i - 1) * 50
		end

		def pages
			meta = @results_hash["response"]["meta"]
			puts JSON.pretty_generate(meta)
			((meta["total_count"] - 1) / meta["limit"]).floor + 1
		end

		def shipstation_date(hs_date)
			hs_date.to_datetime.strftime("%m/%d/%Y %H:%m")
		end

		def handshake_date(ss_date)
			ss_date.gsub!("%2f", "/")
			ss_date.gsub!("%3a", ":")
			start_date = DateTime.strptime(ss_date, "%m/%d/%Y %H:%M")
			start_date.to_datetime.strftime("%FT%T%:z")
		end


end
