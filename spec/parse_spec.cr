require "./spec_helper"

describe TextToSqlSearch do
  it "can parse" do
		t= TextToSqlSearch::Base.new

		lines= {
			">3 doors" => \
			["(1)AND(\"doors\">?)", ["3"]],

			"sedan    4 doors    > 2000 ccm    price < 20k    with    no    downpayment" => \
			["(1)AND(\"sedan\">?)AND(\"doors\"=?)AND(\"ccm\">?)AND(\"price\"<?)AND not(\"downpayment\">?)",
			[                "0",            "4",        "2000",          "20k",                     "0"]],

			"> 3000 ccm or with    stereo" => \
			["(1)AND(\"ccm\">?)or(\"stereo\">?)", ["3000","0"]],

			"((4 door and color = blue) or !downpayment) and price < than 5000" => \
			["(1)AND(((\"door\"=?)and(\"color\"=?))or not(\"downpayment\">?))and(\"price\"<?)",
			[                  "4",          "blue",                    "0",            "5000"]],

			%{color = "metallic red" or year: 2015} => \
			["(1)AND(\"color\"=?)or(\"year\">?)",
			["metallic red", "2015"]],
		}

		lines.each do |i, o|
			t.parse( i).should eq o
		end

  end
end
