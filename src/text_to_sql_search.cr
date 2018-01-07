require "yaml"
require "./text_to_sql_search/**"

module TextToSqlSearch
	DEBUG= true

	class Config
		@infix_operator   = /^[<>=:]$/
		@prefix_operator  = /^[<>=]$/
		@inversion_word    = /^(?:\!|not|no)$/
		@ignored_word     = /^(?:than)/i
		@split_regex      = /"(.*?)"|\s+|([()><:=+!-])/
		@strip            = true
		@default_joiner   = "AND"
		@default_negative = false
		@first_element    = "(1)"
		@passthru_opening = /^[\(]$/
		@passthru_closing = /^[\)]$/
		@and_word         = /^(?:and)/i
		@or_word          = /^(?:or)/i
		@yes_word         = /^(?:\+|has|with|includes)$/
		@no_word          = /^(?:\-|not|no|without)$/
		@value_regex      = /^\d+$/
		@parse_method     = :prefer_infix_operator
		                    #:force_prefix_operator
		                    #:force_infix_operator
		                    #:force_suffix_value
		                    #:prefer_infix_operator
		                    #:prefer_suffix_value
		
		def initialize; end
		
		YAML.mapping(
			infix_operator:   {type: Regex},
			prefix_operator:  {type: Regex},
			inversion_word:   {type: Regex},
			ignored_word:     {type: Regex},
			split_regex:      {type: Regex},
			strip:            {type: Bool},
			default_joiner:   {type: String},
			default_negative: {type: Bool},
			first_element:    {type: String},
			passthru_opening: {type: Regex},
			passthru_closing: {type: Regex},
			and_word:         {type: Regex},
			or_word:          {type: Regex},
			yes_word:         {type: Regex},
			no_word:          {type: Regex},
			value_regex:      {type: Regex},
			parse_method:     {type: Symbol},
		)
	end

	class Base
		# Instantiates new, default config. Returns existing config on subsequent calls.
		def config; @config||= Config.new end
		# Prints debug message if DEBUG==true
		def debug( *arg); DEBUG && STDERR.puts arg.join( " | ").inspect end

		def parse( input)
			# These happen one time to prepare the input line for parsing
			debug input
			input= input.strip if config.strip
			tokens= input.split config.split_regex
			debug tokens
			tokens.reject! {|t| t.blank? }
			debug tokens
			
			# These initialize one-time and accumulate values as parsing advances
			terms= String::Builder.new(config.first_element) # Accumulated SQL WHERE terms
			values= [] of String        # Their corresponding values (replacements for "?"s)
			count= tokens.size          # Total number of tokens we have for parsing
			i= 0                        # Current position in tokens array
			
			# These are re-set to these same defaults after each key=value is fully processed and a new one begins
			joiner= config.default_joiner      # Default joiner to put in SQL between (key=value) pairs
			negative= config.default_negative  # Are we in positive match or negative by default?
			content_before= ""                 # Small accumulator for pass-thru characters like opening parentheses

			while i< count
				debug :in_while
				token= tokens[i].strip if config.strip

				case token
				when config.ignored_word
					i+= 1
					next
				when config.inversion_word
					_, i, negative= on_to_next tokens, i, negative
					next
				when config.passthru_opening
					content_before+= token.not_nil!
					i+= 1
					next
				when config.passthru_closing
					terms<< token
					i+= 1
					next
				when config.and_word
					joiner=token
					i+= 1
					next
				when config.or_word
					joiner=token
					i+= 1
					next
				when config.yes_word
					# Next word is field
					field= tokens[i+=1]
					value= "0"
					op= "+"
				when config.no_word
					# Next word is field
					field= tokens[i+=1]
					value= "0"
					op= "-"
				when config.value_regex
					# Next word is what and we're done
					value= token
					field= tokens[i+=1]
					op= "="
				when config.prefix_operator
					# Next word is value, next after is field
					value= tokens[i+=1]
					field= tokens[i+=1]
					op= token

				else
					# If here, it means we just got a plain word. Now there a couple
					# parsing choices.

					# 1. If we are forcing prefix notation (where operator and value are
					# given before the field), then we treat this field equal to +field.
					# Mode name: force_prefix_operator

					# 2. If we are forcing infix notation and require operator, then this
					# must be followed by operator and value.
					# Mode name: force_infix_operator

					# 3. If we are forcing infix notation with mandatory value (operator
					# optional), then if no operator is present, next token is considered
					# to be value and operator is set to default one.
					# Mode name: force_suffix_value

					# 4. If we prefer infix notation with operator and value, then if
					# operator is present, next field after it is considered value.
					# If operator is not present, field is treated as +field.
					# Mode name: prefer_infix_operator. This is the default.

					# 5. And finally if we prefer value, then if operator is missing and
					# next field looks like value, then we take it and assume default
					# operator. Mode name: prefer_suffix_value

					# items without having to put + in front.
					# So, 'room garage attic' would be same as '+room +garage +attic',
					# or in SQL, room>0 AND garage>0 AND attic>0.

					# Actually, let user choose. One method is that if term is encountered
					# here, it must mean a beginning.
					# Another is, if term is encountered, it is surely last option in the
					# row (i.e. it is identical to +term)

					# Make sure we rewind through insignificant elements, while still taking
					# them into account (like inversion character '!'). This helps us to
					# simplify 
					next_token, i, negative2= on_to_next( tokens, i, negative)
					negative= negative2

					# Important: do not use 'i' below; use only 'i+1' or more.
					# ('i' may be positioned at an inversion character rather than the field
					# name you were expecting to see. For field name, just use 'token'.)

					case config.parse_method
					when :force_prefix_operator
						# Same as YES word
						field= token
						value= "0" # XXX SET DEFAULT VAL
						op= "+"# XXX SET DEFAULT VAL
					when :force_infix_operator
						field= token
						op= tokens[i+=1]
						value= tokens[i+=1]
					when :force_suffix_value
						field= token
						if next_token== :operator
							op= tokens[i+=1]
							value= tokens[i+=1]
						else
							op= "="
							value= tokens[i+=1]
						end
					when :prefer_infix_operator
						if next_token== :operator
							field= token
							op= tokens[i+=1]
							value= tokens[i+=1]
						else
							field= token
							op= "+"
							value= "0"
						end
					when :prefer_suffix_value
						if next_token== :operator
							field= token
							op= tokens[i+=1]
							value= tokens[i+=1]
						elsif next_token== :value
							field= token
							op= "="
							value= tokens[i+=1]
						else
							field= token
							op= "+"
							value= "0"
						end
					end
				end

				text, vals, negative= qualify field, op, value, negative
				terms<< %Q{#{joiner}#{content_before}#{negative ? "not" : ""}(#{text})\n}
				values+= vals

				i+= 1

				# XXX These lines should be kept in sync with the same block before 'while i< count'
				joiner= config.default_joiner      # Default joiner to put in SQL between (key=value) pairs
				negative= config.default_negative  # Are we in positive match or negative by default?
				content_before= ""                 # Small accumulator for pass-thru characters like opening parentheses
			end

			[ terms.to_s, values]
		end
		
		# Given list and current position, peeks into upcoming elements to determine their type.
		# All decision-making is done based on current config.
		def on_to_next( list, i, negation, ignored= nil)
			while el= list[i+=1]?
				next if ignored && el=~ ignored
				return {:operator, i, negation} if el=~ config.infix_operator
				return {:value, i, negation} if el=~ config.value_regex
				if el=~ config.inversion_word
					negation= !negation
					next
				end
				return {:todo, i, negation}
			end
			return {:BUG, 0, true}
		end

	# Resolves aliases if any, then qualifies input to check that everything valid and allowed,
	# and produces the final SQL text chunk and corresponding value to fill in.
	# This method needs work
	def qualify( field, op, value, negative)
		default_operator= {
			"field" => ">"
		}

		field=~ /^[\w\s]+$/ || raise Exception.new "Qualification failed on field #{field}"

		case op
		when ":"
			op= default_operator[field]? || "="
		when "-"
			op= ">"
			negative= !negative
		when "+"
			op= ">"
		end

		op=~ config.infix_operator || raise Exception.new "Qualification failed on op #{op}"

		value=~ /^\w+$/ || raise Exception.new "Qualification failed on value #{value}"

		{ %{"#{field}"#{op}?}, [value], negative}
	end

	end
end
