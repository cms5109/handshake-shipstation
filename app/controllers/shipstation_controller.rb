class ShipstationController < ApplicationController
	before_action :validate_params

	def index
		api_key = params['SS-Username']
		password = params['SS-Password']
		action = params['action']
		offset = page_to_offset(params['page']) if params['page']


		request_uri = "https://#{api_key}:#{password}@app.handshake.com/api/v3/orders?format=xml&limit=50&offset=#{offset}"
		
		begin
			order_export = RestClient.get(request_uri, {"Content-type" => "application/json"}).body
		rescue RestClient::Unauthorized, RestClient::Forbidden => err
			puts 'Cannot create note. Access Denied!'
		rescue RestClient::ExceptionWithResponse => err
			puts err.response
		else
			render xml: handshake_to_shipstation(order_export)
			#json_response = JSON.parse(response.body)
		end

	end

	private
		def handshake_to_shipstation(results)
			@results_hash = Hash.from_xml(results)
			#puts JSON.pretty_generate(@results_hash)
			@xml = ::Builder::XmlMarkup.new(:indent => 3)

			@xml.tag!("Orders", pages: pages){
				@results_hash["response"]["objects"]["object"].each do |order|
					@xml.tag!("Order"){
						@xml.OrderID(cdata(order["objID"]))
						@xml.OrderNumber(cdata(order["id"]))
						@xml.OrderDate(order["ctime"])
						@xml.OrderStatus(cdata(order["status"]))
						@xml.LastModified(order["mtime"])
						@xml.ShippingMethod(cdata(order["shippingMethod"]))
						@xml.PaymentMethod(cdata(order["paymentTerms"]))
						@xml.OrderTotal(order["totalAmount"])
						@xml.TaxAmount
						@xml.ShippingAmount("0.00")
						@xml.CustomerNotes(cdata(order["notes"]))
						@xml.Source(cdata(order["sourceType"]))
						@xml.Customer {
							@xml.CustomerCode cdata(order["customer"]["id"])
							@xml.BillTo {
								@xml.Name cdata(order["customer"]["contact"])
								@xml.Company cdata(order["customer"]["name"])
								@xml.Phone cdata(order["customer"]["billTo"]["phone"])
								@xml.Email cdata(order["customer"]["email"])

							}
							@xml.ShipTo {
								@xml.Name cdata(order["customer"]["contact"])
								@xml.Company cdata(order["customer"]["name"])
								@xml.Address1 cdata(order["shipTo"]["street"])
								@xml.Address2 cdata(order["shipTo"]["street2"])
								@xml.City cdata(order["shipTo"]["city"])
								@xml.State cdata(order["shipTo"]["state"])
								@xml.PostalCode	cdata(order["shipTo"]["postcode"])
								@xml.Country cdata(order["shipTo"]["country"])
								@xml.Phone cdata(order["shipTo"]["phone"])
							}
						} 
						@xml.Items {
							if order["lines"]
								lines_object = order["lines"]["object"]
								lines = lines_object.is_a?(Hash) ? [lines_object] : lines_object
								lines.each do |line|
									@xml.Item {
										@xml.LineItemID cdata(line["objID"])
										@xml.SKU cdata(line["sku"])
										@xml.Name cdata(line["description"])
										@xml.ImageUrl
										@xml.Weight
										@xml.WeightUnits
										@xml.Quantity line["qty"]
										@xml.UnitPrice line["unitPrice"]
										@xml.Location
										@xml.Adjustment
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

		def cdata(data)
			"<![CDATA[#{data}]]>" if data
		end


end
