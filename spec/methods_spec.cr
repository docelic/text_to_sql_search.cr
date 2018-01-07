require "./spec_helper"

describe TextToSqlSearch do
  it "can create config" do
		t= TextToSqlSearch::Base.new
		c = t.config

		tokens= %w(at stage = 7th leg of long ! dreary road)

		t.peek_next(tokens, 0).should eq :todo
		t.peek_next(tokens, 1).should eq :operator
		t.peek_next(tokens, 6).should eq :inversion
		t.peek_next(tokens, 6, /^\!$/).should eq :todo
  end
end
