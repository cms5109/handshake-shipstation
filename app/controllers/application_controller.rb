class ApplicationController < ActionController::API
	before_action :validate_params

	# ActionController::Parameters.action_on_unpermitted_parameters = :raise

	# rescue_from(ActionController::UnpermittedParameters) do |pme|
	# render xml: { error:  { unknown_parameters: pme.params } }, 
	#            status: :bad_request
	# end

	def required_keys
		['SS-UserName', 'SS-Password']
	end

	private
		def validate_params
			puts params.keys
			missing_keys = (required_keys - params.keys)
			response = []
		 	unless missing_keys.count.zero?
		 		missing_keys.each do |required|
		    		response << { missing_parameters: "#{required} is a required parameter" } 
		    	end
		    	render xml: response, status: :bad_request
		    end
		end
end
