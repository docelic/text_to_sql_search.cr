require "./spec_helper"

describe TextToSqlSearch do
  it "can create config" do
		t= TextToSqlSearch::Base.new
		c = t.config

		tokens= %w(at stage = 7th leg of long ! dreary road)

		t.on_to_next(tokens, 0, true)[0].should eq :todo
		t.on_to_next(tokens, 1, true)[0].should eq :operator
		t.on_to_next(tokens, 6, true, /^\!$/)[0].should eq :todo

		type, i, neg= t.on_to_next(tokens, 6, true)
		type.should eq :todo
		neg.should be_false
  end
end
